"""Contexto por petición HTTP (request_id y metadatos para logs estructurados)."""

from __future__ import annotations

from contextvars import ContextVar, Token
from typing import Any

request_id_ctx: ContextVar[str | None] = ContextVar("request_id", default=None)
http_method_ctx: ContextVar[str | None] = ContextVar("http_method", default=None)
http_path_ctx: ContextVar[str | None] = ContextVar("http_path", default=None)


def get_request_id() -> str | None:
    return request_id_ctx.get()


def reset_request_context(
    tokens: list[tuple[ContextVar[Any], Token[Any]]],
) -> None:
    for var, token in reversed(tokens):
        var.reset(token)
