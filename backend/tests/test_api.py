"""
tests/test_api.py
=================
T-15 — Pytest para CleanPool API.
Corre con: pytest backend/tests/ -v
"""

from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from passlib.context import CryptContext

# ── Patch de MongoDB ANTES de importar la app ─────────────────────────────────
# db.py instancia MongoClient al importarse; lo reemplazamos por un mock
# para que los tests no necesiten conexión real a Atlas.
import os

# Set dummy environment variables so pydantic-settings doesn't fail parsing config
os.environ["MONGODB_URI"] = "mongodb://localhost"
os.environ["SECRET_KEY"] = "supersecretkey_for_testing_min_32_chars!!!"

_mock_db = MagicMock()

with patch("pymongo.MongoClient", return_value=MagicMock(**{"__getitem__.return_value": _mock_db})):
    from main import app  # noqa: E402

client = TestClient(app)
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Fixtures ──────────────────────────────────────────────────────────────────
@pytest.fixture(autouse=True)
def reset_mocks():
    """Limpia el estado del mock entre tests."""
    _mock_db.reset_mock()


# ── GET / ─────────────────────────────────────────────────────────────────────
def test_root_returns_200():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "CleanPool API funcionando"}


# ── GET /readings ─────────────────────────────────────────────────────────────
def test_readings_sin_datos():
    """Cuando MongoDB no tiene documentos, retorna mensaje de sin datos."""
    # Forzamos que retorne None explícitamente
    _mock_db["lecturas"].find_one.return_value = None

    response = client.get("/readings")
    assert response.status_code == 200
    assert response.json() == {"message": "Sin lecturas disponibles aún."}


def test_readings_con_datos():
    """Cuando hay un documento, lo retorna con el nuevo formato de estados de T-09."""
    fake_doc = {
        "id_piscina": "p-001",
        "ph": 7.2,
        "temp": 25.0,
        "cloro": 1.5,
        "conductividad": 450.0,
        "timestamp": "2026-03-21T14:00:00+00:00",
    }
    # Forzamos el retorno del dict
    _mock_db["lecturas"].find_one.return_value = fake_doc

    response = client.get("/readings")
    assert response.status_code == 200
    data = response.json()
    assert data["id_piscina"] == "p-001"
    assert data["parametros"]["ph"]["valor"] == 7.2
    assert data["parametros"]["ph"]["estado"] == "optimo"
    # Temp 25.0: 24 <= 25 <= 28 es optimo. En mi anterior assert puse alerta, error mío.
    assert data["parametros"]["temp"]["estado"] == "optimo"
    assert data["parametros"]["cloro"]["estado"] == "optimo"


# ── POST /auth/login ──────────────────────────────────────────────────────────
def test_login_credenciales_incorrectas():
    """Usuario inexistente → 401."""
    _mock_db["usuarios"].find_one.return_value = None

    response = client.post("/auth/login", json={"username": "noexiste", "password": "mal"})
    assert response.status_code == 401
    assert response.json()["detail"] == "Credenciales incorrectas."


def test_login_password_erronea():
    """Usuario existe pero la contraseña es incorrecta → 401."""
    _mock_db["usuarios"].find_one.return_value = {
        "username": "admin",
        "password": _pwd_context.hash("cleanpool2026"),
    }

    response = client.post("/auth/login", json={"username": "admin", "password": "wrong"})
    assert response.status_code == 401


def test_login_exitoso():
    """Credenciales correctas → 200 con access_token."""
    hashed = _pwd_context.hash("cleanpool2026")
    _mock_db["usuarios"].find_one.return_value = {
        "username": "admin",
        "password": hashed,
    }

    response = client.post("/auth/login", json={"username": "admin", "password": "cleanpool2026"})
    assert response.status_code == 200
    body = response.json()
    assert "access_token" in body
    assert body["token_type"] == "bearer"
    assert len(body["access_token"]) > 20  # JWT tiene estructura real
