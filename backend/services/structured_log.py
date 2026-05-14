"""Logs estructurados persistidos en MongoDB (BD de logs, no la operativa)."""

from __future__ import annotations

import asyncio
import logging
import traceback
import uuid
from datetime import datetime, timezone
from typing import Literal

from pydantic import BaseModel, Field

from core.request_context import get_request_id, http_method_ctx, http_path_ctx
from logs_db import get_logs_collection

_logger = logging.getLogger("cleanpool.structured_log")

LogLevel = Literal["INFO", "WARNING", "ERROR", "DEBUG"]
SERVICE_NAME = "cleanpool-backend"


class StructuredLogEntry(BaseModel):
    timestamp: datetime
    level: LogLevel
    service: str = Field(default=SERVICE_NAME)
    module: str
    message: str
    request_id: str
    endpoint: str
    method: str
    status_code: int
    latency_ms: float
    error_type: str | None = None
    stacktrace: str | None = None

    def to_mongo(self) -> dict:
        return self.model_dump()


def _status_to_level(status_code: int) -> LogLevel:
    if status_code >= 500:
        return "ERROR"
    if status_code >= 400:
        return "WARNING"
    return "INFO"


async def persist_structured_log(entry: StructuredLogEntry) -> None:
    coll = get_logs_collection()
    if coll is None:
        return
    try:
        await asyncio.to_thread(coll.insert_one, entry.to_mongo())
    except Exception:
        _logger.exception("Fallo al persistir log estructurado en MongoDB de logs")


def build_http_request_log(
    *,
    module: str,
    message: str,
    request_id: str,
    endpoint: str,
    method: str,
    status_code: int,
    latency_ms: float,
    error_type: str | None = None,
    stacktrace: str | None = None,
    level: LogLevel | None = None,
) -> StructuredLogEntry:
    lvl = level if level is not None else _status_to_level(status_code)
    return StructuredLogEntry(
        timestamp=datetime.now(timezone.utc),
        level=lvl,
        module=module,
        message=message,
        request_id=request_id,
        endpoint=endpoint,
        method=method,
        status_code=status_code,
        latency_ms=latency_ms,
        error_type=error_type,
        stacktrace=stacktrace,
    )


async def log_application_event(
    *,
    level: LogLevel,
    module: str,
    message: str,
    error_type: str | None = None,
    stacktrace: str | None = None,
    status_code: int | None = None,
    latency_ms: float | None = None,
) -> None:
    """
    Registra un evento de aplicación reutilizando el request_id y ruta HTTP
    del contexto actual cuando exista.
    """
    rid = get_request_id() or str(uuid.uuid4())
    method = http_method_ctx.get() or ""
    endpoint = http_path_ctx.get() or ""
    st = status_code if status_code is not None else 0
    lat = latency_ms if latency_ms is not None else 0.0
    entry = StructuredLogEntry(
        timestamp=datetime.now(timezone.utc),
        level=level,
        module=module,
        message=message,
        request_id=rid,
        endpoint=endpoint,
        method=method,
        status_code=st,
        latency_ms=lat,
        error_type=error_type,
        stacktrace=stacktrace,
    )
    await persist_structured_log(entry)


def format_exc_info(exc: BaseException) -> tuple[str, str]:
    """Tipo de error y stacktrace en texto plano."""
    return type(exc).__name__, "".join(
        traceback.format_exception(type(exc), exc, exc.__traceback__)
    )
