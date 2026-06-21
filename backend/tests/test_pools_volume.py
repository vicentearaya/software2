import pytest
import math
from unittest.mock import MagicMock, patch
from bson import ObjectId
from fastapi.testclient import TestClient

from main import app
from db import get_db
from config import get_settings
from services.pool_volume import calcular_volumen
from routers.auth import get_current_user

client = TestClient(app)

@pytest.fixture
def mock_db():
    return MagicMock()

@pytest.fixture
def app_with_mock_db(mock_db):
    def override_get_db():
        return mock_db
    app.dependency_overrides[get_db] = override_get_db
    yield app
    app.dependency_overrides.clear()

@pytest.fixture(autouse=True)
def mock_auth():
    app.dependency_overrides[get_current_user] = lambda: {
        "username": "owner_test",
        "name": "Owner Test"
    }
    yield
    app.dependency_overrides.clear()

class TestPoolVolumeCalculator:
    """Prueba la lógica pura de calcular_volumen según la forma y dimensiones."""
    
    def test_rectangular_volume(self):
        # Piscina 5 x 10 x 1.5 m = 75 m3
        dims = {"largo": 5.0, "ancho": 10.0, "profundidad": 1.5}
        vol = calcular_volumen("rectangular", dims)
        assert pytest.approx(vol, 0.001) == 75.0

    def test_circular_volume(self):
        # Piscina circular de diámetro 4m, profundidad 1.5m
        dims = {"diametro": 4.0, "profundidad": 1.5}
        vol = calcular_volumen("circular", dims)
        expected = math.pi * (2.0 ** 2) * 1.5  # pi * r^2 * p
        assert pytest.approx(vol, 0.001) == expected

    def test_oval_volume(self):
        # Piscina oval de eje largo 10m, eje corto 5m, profundidad 1.5m
        dims = {"eje_largo": 10.0, "eje_corto": 5.0, "profundidad": 1.5}
        vol = calcular_volumen("oval", dims)
        expected = math.pi * 5.0 * 2.5 * 1.5  # pi * (el/2) * (ec/2) * p
        assert pytest.approx(vol, 0.001) == expected

    def test_volumen_conocido_volume(self):
        dims = {"volumen": 123.45}
        vol = calcular_volumen("volumen_conocido", dims)
        assert vol == 123.45

    def test_invalid_shape_raises_value_error(self):
        with pytest.raises(ValueError):
            calcular_volumen("triangular", {"largo": 5.0})


class TestPoolVolumeValidationAPI:
    """Prueba los endpoints de FastAPI y la consistencia de volumen/dimensiones."""

    def test_create_rectangular_pool_consistent(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        mock_db.piscinas.insert_one.return_value = MagicMock(inserted_id=fake_oid)
        
        payload = {
            "nombre": "Mi Rectangular",
            "volumen": 75.0,
            "tipo": "exterior",
            "ubicacion": "patio",
            "forma": "rectangular",
            "dimensiones": {"largo": 5.0, "ancho": 10.0, "profundidad": 1.5}
        }
        
        response = client.post("/piscinas", json=payload)
        assert response.status_code == 201, response.text
        res_data = response.json()
        assert res_data["volumen"] == 75.0
        assert res_data["dimensiones"]["largo"] == 5.0
        assert res_data["largo"] == 5.0
        assert res_data["ancho"] == 10.0
        assert res_data["profundidad"] == 1.5

    def test_create_circular_pool_consistent(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        mock_db.piscinas.insert_one.return_value = MagicMock(inserted_id=fake_oid)
        
        # diametro=4.0, profundidad=1.5 => vol=18.84955592
        payload = {
            "nombre": "Mi Circular",
            "volumen": 18.85,
            "tipo": "exterior",
            "ubicacion": "patio",
            "forma": "circular",
            "dimensiones": {"diametro": 4.0, "profundidad": 1.5}
        }
        
        response = client.post("/piscinas", json=payload)
        assert response.status_code == 201, response.text
        res_data = response.json()
        assert pytest.approx(res_data["volumen"], 0.01) == 18.85
        assert res_data["dimensiones"]["diametro"] == 4.0
        assert res_data["ancho"] == 4.0  # ancho mapped to diameter
        assert res_data["profundidad"] == 1.5
        assert res_data["largo"] == 0.0

    def test_create_pool_inconsistent_volume_rejected(self, app_with_mock_db, mock_db):
        # 5 x 10 x 1.5 = 75.0, but we send 80.0
        payload = {
            "nombre": "Mi Inconsistente",
            "volumen": 80.0,
            "tipo": "exterior",
            "ubicacion": "patio",
            "forma": "rectangular",
            "dimensiones": {"largo": 5.0, "ancho": 10.0, "profundidad": 1.5}
        }
        
        response = client.post("/piscinas", json=payload)
        assert response.status_code == 422
        assert "Inconsistencia de volumen" in response.json()["detail"]

    def test_update_pool_consistent(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        mock_db.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "owner_test",
            "nombre": "Piscina Vieja",
            "volumen": 50.0,
            "tipo": "exterior",
            "ubicacion": "",
            "forma": "rectangular",
            "largo": 10.0,
            "ancho": 5.0,
            "profundidad": 1.0
        }
        mock_db.piscinas.update_one.return_value = MagicMock(matched_count=1)

        payload = {
            "nombre": "Piscina Actualizada",
            "volumen": 75.0,
            "tipo": "exterior",
            "ubicacion": "jardin",
            "forma": "rectangular",
            "dimensiones": {"largo": 5.0, "ancho": 10.0, "profundidad": 1.5}
        }
        
        response = client.put(f"/piscinas/{str(fake_oid)}", json=payload)
        assert response.status_code == 200, response.text
        assert response.json()["volumen"] == 75.0

    def test_update_pool_inconsistent_rejected(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        mock_db.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "owner_test",
            "nombre": "Piscina Vieja",
            "volumen": 50.0,
            "tipo": "exterior",
            "ubicacion": "",
            "forma": "rectangular"
        }
        
        payload = {
            "nombre": "Piscina Actualizada",
            "volumen": 80.0,  # Inconsistent with 5*10*1.5 = 75.0
            "tipo": "exterior",
            "ubicacion": "jardin",
            "forma": "rectangular",
            "dimensiones": {"largo": 5.0, "ancho": 10.0, "profundidad": 1.5}
        }
        
        response = client.put(f"/piscinas/{str(fake_oid)}", json=payload)
        assert response.status_code == 422
        assert "Inconsistencia de volumen" in response.json()["detail"]

    def test_legacy_pool_get_populates_dimensions(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        mock_db.piscinas.find.return_value = [{
            "_id": fake_oid,
            "username": "owner_test",
            "nombre": "Piscina Circular Legacy",
            "volumen": 12.56,
            "tipo": "exterior",
            "ubicacion": "jardin",
            "forma": "circular",
            "ancho": 4.0,  # Legacy diameter was stored in ancho
            "profundidad": 1.0,
            "largo": 0.0
        }]
        
        response = client.get("/piscinas")
        assert response.status_code == 200
        pools = response.json()
        assert len(pools) == 1
        assert pools[0]["dimensiones"]["diametro"] == 4.0
        assert pools[0]["dimensiones"]["profundidad"] == 1.0

    def test_circular_pool_treatment_calculation(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        mock_db.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "owner_test",
            "nombre": "Mi Circular",
            "volumen": 18.84955592153876,
            "tipo": "exterior",
            "ubicacion": "patio",
            "forma": "circular",
            "ancho": 4.0,
            "profundidad": 1.5
        }
        mock_db.mantenimientos.insert_one.return_value = MagicMock()
        mock_db.mantenciones.insert_one.return_value = MagicMock()

        response = client.post(
            f"/piscinas/{str(fake_oid)}/tratamiento",
            json={"ph": 6.8, "cloro": 0.5}
        )
        assert response.status_code == 201, response.text
        data = response.json()
        assert data["ok"] is True
        
        actions = data["tratamiento"]
        assert len(actions) >= 1
        assert actions[0]["producto"] == "Elevador de pH (carbonato de sodio)"
        assert pytest.approx(actions[0]["cantidad"], 0.1) == 848.2


class TestPoolManualVolumeOverride:
    """Verifica la creación y uso de volumen manual override en piscinas."""

    def test_create_oval_pool_with_manual_override_bypasses_validation(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        mock_db.piscinas.insert_one.return_value = MagicMock(inserted_id=fake_oid)

        # Oval dimensions: eje_largo = 10.0, eje_corto = 5.0, profundidad = 1.5
        # Calculated volume: pi * 5 * 2.5 * 1.5 = 58.9048...
        # We manually override volume to 50.0 m³ (which is different by ~15%, well above 5% tolerance)
        payload = {
            "nombre": "Mi Oval Manual",
            "volumen": 50.0,
            "tipo": "exterior",
            "ubicacion": "patio",
            "forma": "oval",
            "volumen_origen": "manual",
            "dimensiones": {"eje_largo": 10.0, "eje_corto": 5.0, "profundidad": 1.5}
        }

        response = client.post("/piscinas", json=payload)
        assert response.status_code == 201, response.text
        res_data = response.json()
        assert res_data["volumen"] == 50.0
        assert res_data["volumen_origen"] == "manual"
        # Calculated volume is saved inside volumen_estimado
        assert pytest.approx(res_data["volumen_estimado"], 0.001) == 58.9048
        # Dimensions are still correct and present
        assert res_data["dimensiones"]["eje_largo"] == 10.0
        assert res_data["dimensiones"]["eje_corto"] == 5.0

    def test_treatment_calculation_uses_manual_volume(self, app_with_mock_db, mock_db):
        fake_oid = ObjectId()
        # Mock database returning a pool with volume override of 50.0 m³
        mock_db.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "owner_test",
            "nombre": "Mi Oval Override",
            "volumen": 50.0,
            "tipo": "exterior",
            "ubicacion": "patio",
            "forma": "oval",
            "volumen_origen": "manual",
            "volumen_estimado": 58.9048,
            "largo": 10.0,
            "ancho": 5.0,
            "profundidad": 1.5,
            "dimensiones": {"eje_largo": 10.0, "eje_corto": 5.0, "profundidad": 1.5}
        }
        mock_db.mantenimientos.insert_one.return_value = MagicMock()
        mock_db.mantenciones.insert_one.return_value = MagicMock()

        # Call treatment calculation for pH 6.8 (target 7.4 => delta = 0.6)
        # Quantity should be based on manual volume (50.0 m³) -> 2250.0 grams of pH elevator
        response = client.post(
            f"/piscinas/{str(fake_oid)}/tratamiento",
            json={"ph": 6.8, "cloro": 2.0}
        )
        assert response.status_code == 201, response.text
        data = response.json()
        assert data["ok"] is True
        
        actions = data["tratamiento"]
        assert len(actions) >= 1
        assert actions[0]["producto"] == "Elevador de pH (carbonato de sodio)"
        assert pytest.approx(actions[0]["cantidad"], 0.1) == 2250.0

