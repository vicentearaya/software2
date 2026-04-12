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


def test_crear_mantencion_exitoso():
    """
    Test Tarea #1, #2, #3: POST /mantenciones con auth y validación schema.
    """
    # Mock de autenticación
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro", "name": "Juan"}
    
    payload = {
        "id_piscina": "PISCINA-001",
        "productos": ["Cloro Triple Acción", "Clarificador"],
        "cantidades": ["1kg", "500ml"],
        "fecha": "2026-04-12T15:30:00"
    }
    
    _mock_db["mantenciones"].insert_one.return_value = MagicMock(inserted_id="fake_id_123")
    
    response = client.post("/mantenciones/", json=payload)
    
    assert response.status_code == 201
    data = response.json()
    assert data["id_piscina"] == "PISCINA-001"
    assert data["username"] == "tecnico_pro"
    assert "Cloro Triple Acción" in data["productos"]
    assert _mock_db["mantenciones"].insert_one.called


def test_crear_mantencion_schema_invalido():
    """
    Test Tarea #2: Validación fallida por tipos incorrectos o falta de campos.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro"}
    
    # Payload incompleto (falta id_piscina)
    payload = {
        "productos": ["Cloro"],
        "cantidades": ["1kg"]
    }
    
    response = client.post("/mantenciones/", json=payload)
    assert response.status_code == 422  # Unprocessable Entity


def test_obtener_historial_vacio():
    """
    Test Tarea #4: GET /mantenciones cuando no hay registros.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "usuario_nuevo"}
    
    # Mock de find que retorna lista vacía
    _mock_db["mantenciones"].find.return_value.sort.return_value = []
    
    response = client.get("/mantenciones/")
    
    assert response.status_code == 200
    assert response.json() == []
    _mock_db["mantenciones"].find.assert_called_with({"username": "usuario_nuevo"})


def test_obtener_historial_con_datos():
    """
    Test Tarea #4: GET /mantenciones con historial existente.
    """
    app.dependency_overrides[get_current_user] = lambda: {"username": "tecnico_pro"}
    
    fake_data = [
        {
            "id_piscina": "P-01",
            "productos": ["A"],
            "cantidades": ["1"],
            "fecha": "2026-04-10T10:00:00",
            "username": "tecnico_pro"
        },
        {
            "id_piscina": "P-01",
            "productos": ["B"],
            "cantidades": ["2"],
            "fecha": "2026-04-11T10:00:00",
            "username": "tecnico_pro"
        }
    ]
    
    _mock_db["mantenciones"].find.return_value.sort.return_value = fake_data
    
    response = client.get("/mantenciones/")
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["id_piscina"] == "P-01"
    assert data[1]["productos"] == ["B"]


def test_mantenciones_sin_autenticacion():
    """
    Test Tarea #1: Acceso denegado si no hay JWT.
    """
    # No agregamos override para get_current_user
    response = client.get("/mantenciones/")
    # Como usamos OAuth2PasswordBearer, FastAPI retorna 401 si falta el header Authorization
    assert response.status_code == 401
