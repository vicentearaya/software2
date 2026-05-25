import os
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

import pytest

os.environ.setdefault("MONGODB_URI", "mongodb://localhost")
os.environ.setdefault("SECRET_KEY", "supersecretkey_for_testing_min_32_chars!!!")
os.environ.setdefault("API_KEY", "dummy_api_key")

from bson import ObjectId

from services.pool_status import build_pool_status_payload


def _lectura_side_effect(stale: bool, *, temp=None, orp=None):
    fresh_ts = datetime.now(timezone.utc) - timedelta(seconds=20)
    stale_ts = datetime.now(timezone.utc) - timedelta(hours=1)

    def find_one(query, *args, **kwargs):
        if "mantenimientos" in str(args):
            return None
        field = None
        if isinstance(query, dict):
            if query.get("temperatura") == {"$exists": True}:
                field = "temperatura"
            elif query.get("orp") == {"$exists": True}:
                field = "orp"
            elif "$or" in query:
                return None
        if field == "temperatura" and temp is not None:
            return {
                "temperatura": temp,
                "timestamp": stale_ts if stale else fresh_ts,
            }
        if field == "orp" and orp is not None:
            return {
                "orp": orp,
                "timestamp": stale_ts if stale else fresh_ts,
            }
        return None

    return find_one


def test_pool_status_ignores_stale_sensor_temperature():
    db = MagicMock()
    oid = ObjectId()
    db.piscinas.find_one.return_value = {"_id": oid, "nombre": "Test"}
    db.lecturas.find_one.side_effect = _lectura_side_effect(True, temp=99.0)
    db.mantenimientos.find_one.return_value = None

    payload = build_pool_status_payload(db, str(oid))

    assert payload["parametros"]["temperatura"]["valor"] is None
    assert payload["parametros"]["temperatura"]["fuente"] == "ninguna"


def test_pool_status_uses_fresh_sensor_temperature():
    db = MagicMock()
    oid = ObjectId()
    db.piscinas.find_one.return_value = {"_id": oid, "nombre": "Test"}
    db.lecturas.find_one.side_effect = _lectura_side_effect(False, temp=25.5)
    db.mantenimientos.find_one.return_value = None

    payload = build_pool_status_payload(db, str(oid))

    assert payload["parametros"]["temperatura"]["valor"] == pytest.approx(25.5)
    assert payload["parametros"]["temperatura"]["fuente"] == "sensor"


def test_pool_status_uses_fresh_orp_without_temperature():
    db = MagicMock()
    oid = ObjectId()
    db.piscinas.find_one.return_value = {"_id": oid, "nombre": "Test"}
    db.lecturas.find_one.side_effect = _lectura_side_effect(False, orp=650.0)
    db.mantenimientos.find_one.return_value = None

    payload = build_pool_status_payload(db, str(oid))

    assert payload["parametros"]["temperatura"]["valor"] is None
    assert payload["parametros"]["orp"]["valor"] == pytest.approx(650.0)
    assert payload["parametros"]["orp"]["fuente"] == "sensor"


def test_pool_status_temp_and_orp_independent():
    db = MagicMock()
    oid = ObjectId()
    pool_id = str(oid)
    db.piscinas.find_one.return_value = {"_id": oid, "nombre": "Test"}
    db.mantenimientos.find_one.return_value = None

    fresh_ts = datetime.now(timezone.utc) - timedelta(seconds=20)

    def find_one(query, *args, **kwargs):
        if isinstance(query, dict) and query.get("temperatura") == {"$exists": True}:
            return {"temperatura": 26.0, "timestamp": fresh_ts}
        if isinstance(query, dict) and query.get("orp") == {"$exists": True}:
            return None
        return None

    db.lecturas.find_one.side_effect = find_one
    payload = build_pool_status_payload(db, pool_id)

    assert payload["parametros"]["temperatura"]["valor"] == pytest.approx(26.0)
    assert payload["parametros"]["orp"]["valor"] is None
