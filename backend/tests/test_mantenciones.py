from unittest.mock import MagicMock, patch
import os
import pytest
from fastapi.testclient import TestClient
from datetime import datetime

# Configurar variables de entorno antes de importar la app
os.environ["MONGODB_URI"] = "mongodb://localhost"
os.environ["SECRET_KEY"] = "supersecretkey_for_testing_min_32_chars!!!"
os.environ["API_KEY"] = "dummy_api_key"

_mock_db = MagicMock()

# Patch de MongoClient para evitar conexión real
with patch("pymongo.MongoClient", return_value=MagicMock(**{"__getitem__.return_value": _mock_db})):
    from main import app
    from routers.auth import get_current_user

client = TestClient(app)

@pytest.fixture(autouse=True)
def reset_mocks():
    """Limpia el estado del mock entre tests."""
    _mock_db.reset_mock()
    app.dependency_overrides.clear()


# ──────────────────────────────────────────────────────────
# POST /mantenciones/
# ──────────────────────────────────────────────────────────

def test_crear_mantencion_exitoso():
    """
    Tarea #1, #2, #3: POST con auth JWT, validación Pydantic y persistencia.
    Incluye los nuevos campos ph, cloro y temperatura.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro", "name": "Juan"}

    payload = {
        "id_piscina": "PISCINA-001",
        "productos": ["Cloro Triple Acción", "Clarificador"],
        "cantidades": ["1kg", "500ml"],
        "fecha": "2026-04-12T15:30:00",
        "ph": 7.4,
        "cloro": 1.5,
        "temperatura": 27.0
    }

    _mock_db["mantenciones"].insert_one.return_value = MagicMock(inserted_id="fake_id_123")

    response = client.post("/mantenciones/", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["id_piscina"] == "PISCINA-001"
    assert data["username"] == "tecnico_pro"
    assert "Cloro Triple Acción" in data["productos"]
    assert data["ph"] == 7.4
    assert data["cloro"] == 1.5
    assert data["temperatura"] == 27.0
    assert _mock_db["mantenciones"].insert_one.called


def test_crear_mantencion_sin_parametros_agua():
    """
    Tarea #2: ph, cloro y temperatura son opcionales — el registro debe funcionar sin ellos.
    Caso de uso: ingreso manual solo de productos/cantidades (sin lectura de sensor).
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro"}

    payload = {
        "id_piscina": "PISCINA-002",
        "productos": ["Algicida"],
        "cantidades": ["250ml"],
        "fecha": "2026-04-13T09:00:00"
        # ph, cloro, temperatura ausentes → deben quedar en None
    }

    _mock_db["mantenciones"].insert_one.return_value = MagicMock(inserted_id="fake_id_456")

    response = client.post("/mantenciones/", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["ph"] is None
    assert data["cloro"] is None
    assert data["temperatura"] is None


def test_crear_mantencion_ph_invalido():
    """
    Tarea #2: Validación de rango — pH fuera del rango [0, 14] debe rechazarse con 422.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro"}

    payload = {
        "id_piscina": "PISCINA-001",
        "productos": ["Cloro"],
        "cantidades": ["1kg"],
        "ph": 15.0,   # inválido: fuera de [0, 14]
    }

    response = client.post("/mantenciones/", json=payload)
    assert response.status_code == 422


def test_crear_mantencion_cloro_negativo():
    """
    Tarea #2: Cloro negativo debe rechazarse con 422.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro"}

    payload = {
        "id_piscina": "PISCINA-001",
        "productos": ["Cloro"],
        "cantidades": ["1kg"],
        "cloro": -0.5,   # inválido: no puede ser negativo
    }

    response = client.post("/mantenciones/", json=payload)
    assert response.status_code == 422


def test_crear_mantencion_schema_invalido():
    """
    Tarea #2: Validación fallida por campos obligatorios ausentes.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro"}

    # Payload incompleto (falta id_piscina)
    payload = {
        "productos": ["Cloro"],
        "cantidades": ["1kg"]
    }

    response = client.post("/mantenciones/", json=payload)
    assert response.status_code == 422  # Unprocessable Entity


# ──────────────────────────────────────────────────────────
# GET /mantenciones/
# ──────────────────────────────────────────────────────────

def test_obtener_historial_vacio():
    """
    Tarea #4: GET /mantenciones cuando no hay registros.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "usuario_nuevo"}

    # Mock de find que retorna lista vacía
    _mock_db["mantenciones"].find.return_value.sort.return_value = []

    response = client.get("/mantenciones/")

    assert response.status_code == 200
    assert response.json() == []
    _mock_db["mantenciones"].find.assert_called_with({"username": "usuario_nuevo"}, {"_id": 0})


def test_obtener_historial_con_datos():
    """
    Tarea #4: GET /mantenciones con historial existente que incluye ph/cloro/temperatura.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro"}

    fake_data = [
        {
            "id_piscina": "P-01",
            "productos": ["Cloro"],
            "cantidades": ["1kg"],
            "fecha": "2026-04-10T10:00:00",
            "username": "tecnico_pro",
            "ph": 7.2,
            "cloro": 1.0,
            "temperatura": 26.5,
            "creado_en": "2026-04-10T10:05:00"
        },
        {
            "id_piscina": "P-01",
            "productos": ["Reductor pH"],
            "cantidades": ["200ml"],
            "fecha": "2026-04-11T10:00:00",
            "username": "tecnico_pro",
            "ph": 8.1,
            "cloro": None,
            "temperatura": 28.0,
            "creado_en": "2026-04-11T10:05:00"
        }
    ]

    _mock_db["mantenciones"].find.return_value.sort.return_value = fake_data

    response = client.get("/mantenciones/")

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["ph"] == 7.2
    assert data[0]["cloro"] == 1.0
    assert data[0]["temperatura"] == 26.5
    assert data[1]["ph"] == 8.1
    assert data[1]["cloro"] is None


# ──────────────────────────────────────────────────────────
# Auth
# ──────────────────────────────────────────────────────────

def test_mantenciones_sin_autenticacion():
    """
    Tarea #1: Acceso denegado si no hay JWT.
    FastAPI retorna 401 cuando falta el header Authorization.
    """
    # No agregamos override para get_current_user → usa el real que requiere token
    response = client.get("/mantenciones/")
    assert response.status_code == 401


def test_crear_mantencion_sin_autenticacion():
    """
    Tarea #1: POST también debe fallar sin JWT.
    """
    payload = {
        "id_piscina": "P-01",
        "productos": ["Cloro"],
        "cantidades": ["1kg"]
    }
    response = client.post("/mantenciones/", json=payload)
    assert response.status_code == 401
