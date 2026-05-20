"""Middleware: request_id, medición de latencia y persistencia de logs HTTP en MongoDB de logs."""

from __future__ import annotations

import time
import uuid
from typing import Any

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response

from core.request_context import (
    http_method_ctx,
    http_path_ctx,
    request_id_ctx,
    reset_request_context,
)
from services.structured_log import (
    build_http_request_log,
    format_exc_info,
    persist_structured_log,
)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next) -> Response:
        request_id = str(uuid.uuid4())
        tokens: list[tuple[Any, Any]] = [
            (request_id_ctx, request_id_ctx.set(request_id)),
            (http_method_ctx, http_method_ctx.set(request.method)),
            (http_path_ctx, http_path_ctx.set(request.url.path)),
        ]
        request.state.request_id = request_id
        start = time.perf_counter()
        try:
            response = await call_next(request)
        except Exception as exc:
            latency_ms = (time.perf_counter() - start) * 1000
            err_type, stack = format_exc_info(exc)
            entry = build_http_request_log(
                module="middleware",
                message=f"{request.method} {request.url.path} -> excepción no controlada",
                request_id=request_id,
                endpoint=request.url.path,
                method=request.method,
                status_code=500,
                latency_ms=latency_ms,
                level="ERROR",
                error_type=err_type,
                stacktrace=stack,
            )
            await persist_structured_log(entry)
            raise
        finally:
            reset_request_context(tokens)

        latency_ms = (time.perf_counter() - start) * 1000
        status_code = response.status_code
        entry = build_http_request_log(
            module="middleware",
            message=f"{request.method} {request.url.path} -> {status_code}",
            request_id=request_id,
            endpoint=request.url.path,
            method=request.method,
            status_code=status_code,
            latency_ms=latency_ms,
        )
        await persist_structured_log(entry)
        return response
