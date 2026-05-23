import json
import os
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

import pytest

os.environ.setdefault("MONGODB_URI", "mongodb://localhost")
os.environ.setdefault("SECRET_KEY", "supersecretkey_for_testing_min_32_chars!!!")
os.environ.setdefault("API_KEY", "dummy_api_key")

from services.device_presence import (
    is_device_online,
    is_reading_fresh,
    parse_temperature_payload,
    process_mqtt_temperature_message,
    resolve_pool_from_mqtt_topic,
)


def test_parse_temperature_payload_json():
    raw = json.dumps({"temperatura": 26.42}).encode()
    assert parse_temperature_payload(raw) == pytest.approx(26.42)


def test_parse_temperature_payload_plain():
    assert parse_temperature_payload("25.5") == pytest.approx(25.5)


def test_is_reading_fresh_recent():
    ts = datetime.now(timezone.utc) - timedelta(seconds=30)
    assert is_reading_fresh(ts) is True


def test_is_reading_fresh_stale():
    ts = datetime.now(timezone.utc) - timedelta(minutes=10)
    assert is_reading_fresh(ts) is False


def test_is_device_online():
    now = datetime.now(timezone.utc)
    assert is_device_online(now - timedelta(seconds=20)) is True
    assert is_device_online(now - timedelta(minutes=10)) is False


def test_resolve_pool_from_mqtt_topic_by_slug():
    db = MagicMock()
    db.device_bindings.find_one.return_value = {
        "pool_id": "507f1f77bcf86cd799439011",
        "device_id": "cleanpool-001",
    }
    resolved = resolve_pool_from_mqtt_topic(db, "piscina-1")
    assert resolved == ("507f1f77bcf86cd799439011", "cleanpool-001")


def test_process_mqtt_temperature_message_ok():
    db = MagicMock()
    db.device_bindings.find_one.return_value = {
        "pool_id": "pool-abc",
        "device_id": "dev-1",
    }
    db.lecturas.insert_one.return_value = MagicMock(inserted_id="x1")

    ok = process_mqtt_temperature_message(
        db,
        "cleanpool/piscina-1/temperatura",
        b'{"temperatura":11.75}',
    )

    assert ok is True
    db.lecturas.insert_one.assert_called_once()
    db.device_bindings.update_one.assert_called_once()
