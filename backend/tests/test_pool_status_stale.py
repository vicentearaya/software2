import os
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

import pytest

os.environ.setdefault("MONGODB_URI", "mongodb://localhost")
os.environ.setdefault("SECRET_KEY", "supersecretkey_for_testing_min_32_chars!!!")
os.environ.setdefault("API_KEY", "dummy_api_key")

from bson import ObjectId

from services.pool_status import build_pool_status_payload


def test_pool_status_ignores_stale_sensor_temperature():
    db = MagicMock()
    oid = ObjectId()
    db.piscinas.find_one.return_value = {"_id": oid, "nombre": "Test"}
    db.lecturas.find_one.return_value = {
        "pool_id": str(oid),
        "temperatura": 99.0,
        "timestamp": datetime.now(timezone.utc) - timedelta(hours=1),
    }
    db.mantenimientos.find_one.return_value = None

    payload = build_pool_status_payload(db, str(oid))

    assert payload["parametros"]["temperatura"]["valor"] is None
    assert payload["parametros"]["temperatura"]["fuente"] == "ninguna"


def test_pool_status_uses_fresh_sensor_temperature():
    db = MagicMock()
    oid = ObjectId()
    db.piscinas.find_one.return_value = {"_id": oid, "nombre": "Test"}
    db.lecturas.find_one.return_value = {
        "pool_id": str(oid),
        "temperatura": 25.5,
        "timestamp": datetime.now(timezone.utc) - timedelta(seconds=20),
    }
    db.mantenimientos.find_one.return_value = None

    payload = build_pool_status_payload(db, str(oid))

    assert payload["parametros"]["temperatura"]["valor"] == pytest.approx(25.5)
    assert payload["parametros"]["temperatura"]["fuente"] == "sensor"
