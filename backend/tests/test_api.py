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
os.environ["API_KEY"] = "dummy_api_key"

_mock_db = MagicMock()

with patch("pymongo.MongoClient", return_value=MagicMock(**{"__getitem__.return_value": _mock_db})):
    from main import app  # noqa: E402
    from db import get_db
    import routers.auth as _auth_mod

client = TestClient(app)
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Fixtures ──────────────────────────────────────────────────────────────────
@pytest.fixture(autouse=True)
def reset_mocks():
    """Limpia el estado del mock entre tests."""
    _mock_db.reset_mock()
    # Asegurar que get_db siempre devuelve nuestro mock
    app.dependency_overrides[get_db] = lambda: _mock_db
    # Parchar _db a nivel de módulo en auth (usa _db directamente)
    _auth_mod._db = _mock_db
    yield
    app.dependency_overrides.clear()


# ── GET / ─────────────────────────────────────────────────────────────────────
def test_root_returns_200():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "CleanPool API funcionando"}


# ── GET /lecturas/estado ──────────────────────────────────────────────────────
def test_lecturas_estado_sin_datos():
    """Cuando MongoDB no tiene lecturas para un pool_id, retorna 404."""
    _mock_db.lecturas.find_one.return_value = None

    response = client.get("/lecturas/estado", params={"pool_id": "pool_inexistente"})
    assert response.status_code == 404
    assert response.json()["detail"] == "No se encontraron mediciones para esta piscina"


def test_lecturas_estado_con_datos():
    """Cuando hay un documento, retorna evaluación completa con estados."""
    fake_doc = {
        "pool_id": "p-001",
        "ph": 7.2,
        "cloro": 1.5,
        "temperatura": 25.0,
        "conductividad": 1500.0,
        "timestamp": "2026-03-21T14:00:00+00:00",
    }
    _mock_db.lecturas.find_one.return_value = fake_doc
    # Mock del pool (para volumen) — readings.py usa db.pools (atributo)
    _mock_db.pools.find_one.return_value = {
        "pool_id": "p-001",
        "volumen_m3": 50.0,
    }

    response = client.get("/lecturas/estado", params={"pool_id": "p-001"})
    assert response.status_code == 200
    data = response.json()
    assert data["piscina_apta"] is True
    assert "detalle_sensores" in data
    assert data["detalle_sensores"]["ph"]["estado"] == "OPTIMO"
    assert data["detalle_sensores"]["cloro"]["estado"] == "OPTIMO"


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


def test_login_missing_fields():
    """Faltan campos requeridos (ej. password) --> 422 Unprocessable Entity."""
    response = client.post("/auth/login", json={"username": "admin"})
    assert response.status_code == 422
    assert "detail" in response.json()


# -- POST /auth/register
def test_register_usuario_existente():
    """Si el usuario ya existe, retorna 400 Bad Request."""
    _mock_db["usuarios"].find_one.return_value = {"username": "testuser"}

    response = client.post(
        "/auth/register",
        json={"name": "Test User", "username": "testuser", "email": "test@test.com", "password": "password123"}
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "El correo o nombre de usuario ya está registrado."


def test_register_exitoso():
    """Registro exitoso retorna JWT y codigo 201."""
    _mock_db["usuarios"].find_one.return_value = None
    _mock_db["usuarios"].insert_one.return_value = MagicMock(inserted_id="fake_id")

    response = client.post(
        "/auth/register",
        json={"name": "New User", "username": "newuser", "email": "new@test.com", "password": "password123"}
    )
    assert response.status_code == 201
    body = response.json()
    assert body["success"] is True
    assert "token" in body
    assert body["user"]["email"] == "new@test.com"
    assert body["user"]["username"] == "newuser"
