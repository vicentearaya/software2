import os
from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException

os.environ.setdefault("MONGODB_URI", "mongodb://localhost")
os.environ.setdefault("SECRET_KEY", "supersecretkey_for_testing_min_32_chars!!!")
os.environ.setdefault("API_KEY", "dummy_api_key")

from routers.ingesta import ingest_data, ingest_lectura, verify_api_key
from models import LecturaIn, LecturaInCompat


class _Settings:
    api_key = "valid-key"


def test_verify_api_key_ok():
    verify_api_key("valid-key", _Settings())


def test_verify_api_key_forbidden():
    with pytest.raises(HTTPException) as exc:
        verify_api_key("bad-key", _Settings())
    assert exc.value.status_code == 403


def test_ingest_lectura_persiste_criticidad_true():
    db = MagicMock()
    db.lecturas.insert_one.return_value = MagicMock(inserted_id="abc123")
    lectura = LecturaIn(
        pool_id="pool-1",
        ph=5.0,
        cloro=2.0,
        temperatura=27.0,
        conductividad=1200.0,
    )

    result = ingest_lectura(lectura, db=db, _=None)

    assert result.ok is True
    assert result.is_critical is True
    inserted_doc = db.lecturas.insert_one.call_args.args[0]
    assert inserted_doc["pool_id"] == "pool-1"
    assert inserted_doc["is_critical"] is True


def test_ingest_data_legacy_ph_fuera_de_rango():
    db = MagicMock()
    lectura = LecturaInCompat(
        id_piscina="pool-1",
        ph=20.0,
        cloro=1.5,
        temp=25.0,
        conductividad=1000.0,
    )

    result = ingest_data(lectura, db=db, _=None)

    assert result["statusCode"] == 400
    assert result["rejected"] is True
    db.lecturas.insert_one.assert_not_called()
