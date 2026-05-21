"""
tests/test_api.py
=================
T-15 — Pytest para CleanPool API.
Corre con: pytest backend/tests/ -v
"""

from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

import pytest
from bson import ObjectId
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
    from routers.auth import get_current_user  # noqa: E402

client = TestClient(app)
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Fixtures ──────────────────────────────────────────────────────────────────
@pytest.fixture(autouse=True)
def reset_mocks():
    """Limpia el estado del mock entre tests."""
    _mock_db.reset_mock()
    # Asegurar que get_db siempre devuelve nuestro mock
    app.dependency_overrides[get_db] = lambda: _mock_db
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


# ── GET /inventario (JWT override) ───────────────────────────────────────────
def _inv_doc(oid, cantidad=100.0, username="admin"):
    return {
        "_id": oid,
        "username": username,
        "nombre": "Cloro",
        "categoria": "Desinfectante",
        "cantidad": cantidad,
        "unidad": "g",
        "notas": None,
        "creado_en": datetime(2026, 1, 15, 12, 0, 0, tzinfo=timezone.utc),
    }


def test_inventario_listar():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    oid = ObjectId()
    doc = _inv_doc(oid)

    class _Cursor:
        def sort(self, *a, **k):
            return [doc]

    _mock_db["inventario"].find.return_value = _Cursor()
    response = client.get("/inventario")
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 1
    assert data["items"][0]["nombre"] == "Cloro"
    assert data["items"][0]["cantidad"] == 100.0
    assert data["items"][0]["unidad"] == "g"
    assert data["items"][0]["id"] == str(oid)


def test_inventario_crear():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    oid = ObjectId()
    doc = _inv_doc(oid, cantidad=500.0)
    _mock_db["inventario"].insert_one.return_value = MagicMock(inserted_id=oid)
    _mock_db["inventario"].find_one.return_value = doc

    response = client.post(
        "/inventario",
        json={
            "nombre": "Cloro",
            "categoria": "Desinfectante",
            "cantidad": 500,
            "unidad": "g",
            "notas": None,
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["cantidad"] == 500.0
    assert body["categoria"] == "Desinfectante"


def test_inventario_agregar_stock():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    oid = ObjectId()
    updated = _inv_doc(oid, cantidad=600.0)
    _mock_db["inventario"].find_one_and_update.return_value = updated

    response = client.post(f"/inventario/{oid}/agregar", json={"cantidad": 100})
    assert response.status_code == 200
    assert response.json()["cantidad"] == 600.0


def test_inventario_agregar_not_found():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    _mock_db["inventario"].find_one_and_update.return_value = None

    response = client.post(f"/inventario/{ObjectId()}/agregar", json={"cantidad": 10})
    assert response.status_code == 404


def test_inventario_usar_stock_ok():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    oid = ObjectId()
    updated = _inv_doc(oid, cantidad=400.0)
    _mock_db["inventario"].find_one_and_update.return_value = updated

    response = client.post(f"/inventario/{oid}/usar", json={"cantidad": 100})
    assert response.status_code == 200
    assert response.json()["cantidad"] == 400.0


def test_inventario_usar_mas_del_disponible():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    oid = ObjectId()
    _mock_db["inventario"].find_one_and_update.return_value = None
    _mock_db["inventario"].find_one.return_value = _inv_doc(oid, cantidad=50.0)

    response = client.post(f"/inventario/{oid}/usar", json={"cantidad": 100})
    assert response.status_code == 422
    assert response.json()["detail"] == "No puedes usar más del stock disponible"


def test_inventario_usar_producto_no_encontrado():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    oid = ObjectId()
    _mock_db["inventario"].find_one_and_update.return_value = None
    _mock_db["inventario"].find_one.return_value = None

    response = client.post(f"/inventario/{oid}/usar", json={"cantidad": 1})
    assert response.status_code == 404
    assert response.json()["detail"] == "Producto no encontrado"


def test_inventario_id_invalido():
    app.dependency_overrides[get_current_user] = lambda: {"username": "admin"}
    response = client.post("/inventario/not-an-objectid/agregar", json={"cantidad": 1})
    assert response.status_code == 400
