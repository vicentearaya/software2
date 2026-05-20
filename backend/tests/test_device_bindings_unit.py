import os
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException

os.environ.setdefault("MONGODB_URI", "mongodb://localhost")
os.environ.setdefault("SECRET_KEY", "supersecretkey_for_testing_min_32_chars!!!")
os.environ.setdefault("API_KEY", "dummy_api_key")

from models import DeviceBindingIn, LecturaTemperaturaDeviceIn
from routers.device_bindings import (
    bind_device_to_pool,
    get_device_status,
    ingest_temperature_from_device,
    unbind_device_from_pool,
    verify_api_key,
)


class _Settings:
    api_key = "valid-key"


@pytest.fixture
def current_user():
    return {"username": "tech"}


def test_verify_api_key_device_bindings_forbidden():
    with pytest.raises(HTTPException) as exc:
        verify_api_key("invalid", _Settings())
    assert exc.value.status_code == 403


def test_bind_device_pool_id_invalido(current_user):
    db = MagicMock()
    payload = DeviceBindingIn(device_id="dev-1", pool_id="invalido")

    with pytest.raises(HTTPException) as exc:
        bind_device_to_pool(payload, current_user=current_user, db=db)
    assert exc.value.status_code == 400


def test_unbind_device_no_activo(current_user):
    db = MagicMock()
    db.device_bindings.find_one.return_value = None
    payload = DeviceBindingIn(device_id="dev-1", pool_id="pool-1")

    with pytest.raises(HTTPException) as exc:
        unbind_device_from_pool(payload, current_user=current_user, db=db)
    assert exc.value.status_code == 404


def test_get_device_status_online(current_user):
    db = MagicMock()
    now = datetime.now(timezone.utc)
    db.device_bindings.find_one.return_value = {
        "device_id": "dev-1",
        "pool_id": "pool-1",
        "active": True,
        "assigned_at": now - timedelta(days=1),
        "last_seen_at": now - timedelta(minutes=1),
    }

    status = get_device_status("dev-1", current_user=current_user, db=db)

    assert status.is_online is True
    assert status.connection_state == "ONLINE"


def test_ingest_temperature_from_device_sin_binding():
    db = MagicMock()
    db.device_bindings.find_one.return_value = None
    payload = LecturaTemperaturaDeviceIn(device_id="dev-404", temperatura=26.5)

    with pytest.raises(HTTPException) as exc:
        ingest_temperature_from_device(payload, db=db, _=None)
    assert exc.value.status_code == 404


def test_ingest_temperature_from_device_ok():
    db = MagicMock()
    db.device_bindings.find_one.return_value = {"pool_id": "pool-1"}
    db.lecturas.insert_one.return_value = MagicMock(inserted_id="ins-1")
    payload = LecturaTemperaturaDeviceIn(device_id="dev-1", temperatura=26.5)

    response = ingest_temperature_from_device(payload, db=db, _=None)

    assert response.ok is True
    assert response.is_critical is False
    db.device_bindings.update_one.assert_called_once()
