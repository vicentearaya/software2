"""Tests del logger estructurado hacia MongoDB de logs."""

from __future__ import annotations

import asyncio
import os
from unittest.mock import MagicMock, patch

os.environ.setdefault("MONGODB_URI", "mongodb://localhost")
os.environ.setdefault("SECRET_KEY", "supersecretkey_for_testing_min_32_chars!!!")
os.environ.setdefault("API_KEY", "dummy_api_key")

with patch("pymongo.MongoClient", return_value=MagicMock()):
    from services.structured_log import (
        build_http_request_log,
        persist_structured_log,
    )


def test_build_http_request_log_shape():
    entry = build_http_request_log(
        module="middleware",
        message="GET / -> 200",
        request_id="550e8400-e29b-41d4-a716-446655440000",
        endpoint="/",
        method="GET",
        status_code=200,
        latency_ms=1.23,
    )
    doc = entry.to_mongo()
    assert doc["service"] == "cleanpool-backend"
    assert doc["level"] == "INFO"
    assert doc["module"] == "middleware"
    assert doc["request_id"] == "550e8400-e29b-41d4-a716-446655440000"
    assert doc["endpoint"] == "/"
    assert doc["method"] == "GET"
    assert doc["status_code"] == 200
    assert doc["latency_ms"] == 1.23
    assert doc["error_type"] is None
    assert doc["stacktrace"] is None
    assert doc["timestamp"].tzinfo is not None


def test_build_http_request_log_levels_by_status():
    assert build_http_request_log(
        module="m",
        message="x",
        request_id="550e8400-e29b-41d4-a716-446655440000",
        endpoint="/",
        method="GET",
        status_code=404,
        latency_ms=0.0,
    ).level == "WARNING"
    assert build_http_request_log(
        module="m",
        message="x",
        request_id="550e8400-e29b-41d4-a716-446655440000",
        endpoint="/",
        method="GET",
        status_code=500,
        latency_ms=0.0,
    ).level == "ERROR"


def test_persist_skips_when_no_logs_collection():
    entry = build_http_request_log(
        module="m",
        message="x",
        request_id="550e8400-e29b-41d4-a716-446655440000",
        endpoint="/",
        method="GET",
        status_code=200,
        latency_ms=0.0,
    )
    with patch("services.structured_log.get_logs_collection", return_value=None):
        asyncio.run(persist_structured_log(entry))


def test_persist_insert_one():
    mock_coll = MagicMock()
    entry = build_http_request_log(
        module="m",
        message="x",
        request_id="550e8400-e29b-41d4-a716-446655440000",
        endpoint="/a",
        method="POST",
        status_code=201,
        latency_ms=2.5,
    )
    with patch("services.structured_log.get_logs_collection", return_value=mock_coll):
        asyncio.run(persist_structured_log(entry))
    mock_coll.insert_one.assert_called_once()
