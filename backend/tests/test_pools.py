"""
test_pools.py — Tests para endpoints CRUD de Piscinas (Tarea #66)

Verifica que:
1. Las piscinas creadas sin settings adoptan los defaults de la industria
2. Las piscinas creadas con settings personalizados se persisten correctamente
3. Los endpoints GET retornan correctamente la configuración anidada
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime
from unittest.mock import MagicMock, patch

# Importar app y modelos
from main import app
from models import PoolIn, PoolSettings
from db import get_db


# Cliente de prueba
client = TestClient(app)


# Mock de la base de datos
@pytest.fixture
def mock_db():
    """Fixture que proporciona un mock de MongoDB para pruebas"""
    db = MagicMock()
    return db


@pytest.fixture
def app_with_mock_db(mock_db):
    """Fixture que inyecta el mock en la app"""
    def override_get_db():
        return mock_db
    
    app.dependency_overrides[get_db] = override_get_db
    yield app
    app.dependency_overrides.clear()


class TestPoolCreationWithDefaultSettings:
    """
    Test Case: Creación de piscina SIN especificar settings.
    
    Implementa: test_pool_creation_default_settings
    Tarea #66 - US-10
    """

    def test_pool_creation_default_settings(self, app_with_mock_db):
        """
        Prueba que una piscina creada SIN settings reciba los defaults de la industria.
        
        Scenario:
        - POST /api/v1/pools con PoolIn (sin settings)
        - MongoDB retorna el documento insertado
        
        Expected:
        - HTTP 201
        - Respuesta incluye settings con valores por defecto de la industria
        - ph: 7.2 - 7.8
        - cloro: 1.0 - 3.0 ppm
        - temperatura: 24.0 - 30.0 °C
        - conductividad: 1000.0 - 2000.0 µS/cm
        """
        # Arrange
        pool_payload = {
            "pool_id": "POOL_TEST_001",
            "nombre": "Piscina de Prueba",
            "volumen_m3": 50.0,
            "activo": True
            # NO incluir settings - debe usar defaults
        }

        # Mock de MongoDB insert_one
        mock_insert_result = MagicMock()
        mock_insert_result.inserted_id = "ObjectId_123"
        
        # Obtener el mock_db del override
        mock_db = app.dependency_overrides[get_db]()
        mock_db.pools.find_one.return_value = None  # Pool no existe aún
        mock_db.pools.insert_one.return_value = mock_insert_result

        # Act
        with patch('routers.pools.get_db', return_value=mock_db):
            response = client.post("/api/v1/pools", json=pool_payload)

        # Assert
        assert response.status_code == 201, f"Status {response.status_code}, Body: {response.text}"
        
        data = response.json()
        assert data["ok"] is True
        assert data["pool_id"] == "POOL_TEST_001"
        assert data["nombre"] == "Piscina de Prueba"
        
        # Verificar que settings está presente con defaults de industria
        assert "settings" in data
        settings = data["settings"]
        
        # Defaults de industria
        assert settings["ph_min"] == 7.2, "pH mínimo debe ser 7.2 (default industria)"
        assert settings["ph_max"] == 7.8, "pH máximo debe ser 7.8 (default industria)"
        assert settings["cloro_min"] == 1.0, "Cloro mínimo debe ser 1.0 ppm (default industria)"
        assert settings["cloro_max"] == 3.0, "Cloro máximo debe ser 3.0 ppm (default industria)"
        assert settings["temperatura_min"] == 24.0, "Temperatura mínima debe ser 24.0°C (default industria)"
        assert settings["temperatura_max"] == 30.0, "Temperatura máxima debe ser 30.0°C (default industria)"
        assert settings["conductividad_min"] == 1000.0, "Conductividad mínima debe ser 1000.0 µS/cm (default industria)"
        assert settings["conductividad_max"] == 2000.0, "Conductividad máxima debe ser 2000.0 µS/cm (default industria)"


class TestPoolCreationWithCustomSettings:
    """
    Test Case: Creación de piscina CON settings personalizados.
    
    Implementa: test_pool_creation_custom_settings
    Tarea #66 - US-10
    """

    def test_pool_creation_custom_settings(self, app_with_mock_db):
        """
        Prueba que una piscina creada CON settings personalizados los persista correctamente.
        
        Scenario:
        - POST /api/v1/pools con PoolIn + settings personalizado
        - Especificar rangos diferentes a los defaults (ej. piscina infantil con tolerancias menores)
        - Verificar que MongoDB lo guarde y lo retorne correctamente
        
        Expected:
        - HTTP 201
        - Respuesta incluye settings con valores personalizados
        - pH: 7.0 - 7.5 (más estrecho que default 7.2-7.8)
        - Cloro: 0.8 - 2.5 ppm (más bajo para piscina infantil)
        """
        # Arrange
        pool_payload = {
            "pool_id": "POOL_INFANTIL_001",
            "nombre": "Piscina Infantil",
            "volumen_m3": 20.0,
            "activo": True,
            "settings": {
                "ph_min": 7.0,
                "ph_max": 7.5,
                "cloro_min": 0.8,
                "cloro_max": 2.5,
                "temperatura_min": 26.0,
                "temperatura_max": 32.0,
                "conductividad_min": 800.0,
                "conductividad_max": 1500.0
            }
        }

        # Mock de MongoDB
        mock_insert_result = MagicMock()
        mock_insert_result.inserted_id = "ObjectId_456"
        
        mock_db = app.dependency_overrides[get_db]()
        mock_db.pools.find_one.return_value = None
        mock_db.pools.insert_one.return_value = mock_insert_result

        # Act
        with patch('routers.pools.get_db', return_value=mock_db):
            response = client.post("/api/v1/pools", json=pool_payload)

        # Assert
        assert response.status_code == 201, f"Status {response.status_code}, Body: {response.text}"
        
        data = response.json()
        assert data["ok"] is True
        assert data["pool_id"] == "POOL_INFANTIL_001"
        
        # Verificar que settings personalizado fue guardado
        assert "settings" in data
        settings = data["settings"]
        
        # Valores personalizados (no defaults)
        assert settings["ph_min"] == 7.0, "pH mínimo personalizado debe ser 7.0"
        assert settings["ph_max"] == 7.5, "pH máximo personalizado debe ser 7.5"
        assert settings["cloro_min"] == 0.8, "Cloro mínimo personalizado debe ser 0.8 ppm"
        assert settings["cloro_max"] == 2.5, "Cloro máximo personalizado debe ser 2.5 ppm"
        assert settings["temperatura_min"] == 26.0, "Temperatura mínima personalizada debe ser 26.0°C"
        assert settings["temperatura_max"] == 32.0, "Temperatura máxima personalizada debe ser 32.0°C"
        assert settings["conductividad_min"] == 800.0, "Conductividad mínima personalizada debe ser 800.0 µS/cm"
        assert settings["conductividad_max"] == 1500.0, "Conductividad máxima personalizada debe ser 1500.0 µS/cm"


class TestPoolListWithSettings:
    """
    Test Case: Listado de piscinas retorna settings correctamente.
    
    Verifica que GET /api/v1/pools incluya el campo settings en cada piscina.
    """

    def test_pool_list_includes_settings(self, app_with_mock_db):
        """
        Prueba que GET /api/v1/pools retorna piscinas con sus respectivos settings.
        
        Expected:
        - HTTP 200
        - Cada pool en la lista tiene un campo "settings" poblado
        """
        # Arrange
        pools_data = [
            {
                "pool_id": "POOL_001",
                "nombre": "Piscina Principal",
                "volumen_m3": 50.0,
                "activo": True,
                "settings": {
                    "ph_min": 7.2,
                    "ph_max": 7.8,
                    "cloro_min": 1.0,
                    "cloro_max": 3.0,
                    "temperatura_min": 24.0,
                    "temperatura_max": 30.0,
                    "conductividad_min": 1000.0,
                    "conductividad_max": 2000.0
                },
                "creado_en": datetime.utcnow().isoformat()
            },
            {
                "pool_id": "POOL_002",
                "nombre": "Piscina Infantil",
                "volumen_m3": 20.0,
                "activo": True,
                "settings": {
                    "ph_min": 7.0,
                    "ph_max": 7.5,
                    "cloro_min": 0.8,
                    "cloro_max": 2.5,
                    "temperatura_min": 26.0,
                    "temperatura_max": 32.0,
                    "conductividad_min": 800.0,
                    "conductividad_max": 1500.0
                },
                "creado_en": datetime.utcnow().isoformat()
            }
        ]

        # Mock de MongoDB find
        mock_db = app.dependency_overrides[get_db]()
        mock_db.pools.find.return_value.sort.return_value = pools_data

        # Act
        with patch('routers.pools.get_db', return_value=mock_db):
            response = client.get("/api/v1/pools")

        # Assert
        assert response.status_code == 200
        
        data = response.json()
        assert data["total"] == 2
        assert len(data["pools"]) == 2
        
        # Verificar que cada pool tiene settings
        for pool in data["pools"]:
            assert "settings" in pool, "Cada pool debe tener campo 'settings'"
            assert isinstance(pool["settings"], dict), "settings debe ser un diccionario"
            assert "ph_min" in pool["settings"]
            assert "cloro_max" in pool["settings"]


class TestPoolSettingsValidation:
    """
    Test Case: Validación de values en PoolSettings.
    
    Verifica que Pydantic valide correctamente los rangos.
    """

    def test_pool_settings_pydantic_validation(self):
        """
        Prueba que PoolSettings valida correctamente los valores.
        
        Ej: pH debe estar entre 0 y 14
        Los valores negativos deben rechazarse
        """
        # Arrange - Valores inválidos
        invalid_settings = {
            "ph_min": -1.0,  # Inválido: pH no puede ser negativo
            "ph_max": 7.8,
            "cloro_min": 1.0,
            "cloro_max": 3.0,
            "temperatura_min": 24.0,
            "temperatura_max": 30.0,
            "conductividad_min": 1000.0,
            "conductividad_max": 2000.0
        }

        # Act & Assert - Pydantic debe rechazar pH negativo
        with pytest.raises(ValueError):
            PoolSettings(**invalid_settings)

    def test_pool_settings_defaults(self):
        """
        Prueba que PoolSettings crea defaults correctamente sin argumentos.
        
        Expected:
        - PoolSettings() sin args devuelve defaults de industria
        """
        # Act
        settings = PoolSettings()

        # Assert
        assert settings.ph_min == 7.2
        assert settings.ph_max == 7.8
        assert settings.cloro_min == 1.0
        assert settings.cloro_max == 3.0
        assert settings.temperatura_min == 24.0
        assert settings.temperatura_max == 30.0
        assert settings.conductividad_min == 1000.0
        assert settings.conductividad_max == 2000.0
<<<<<<< HEAD


class TestPoolUserAssociation:
    """
    Test Cases para asociación de pools a usuarios (Tarea: Opción A)
    
    Verifica que:
    1. No se puede crear dos pools con el mismo pool_id para el mismo usuario
    2. Se puede crear un pool con el mismo pool_id pero para distinto usuario
    3. GET lista pools solo retorna pools del usuario autenticado
    """

    def test_duplicate_pool_same_user_returns_400(self, app_with_mock_db):
        """
        CASO 1: Mismo pool_id, mismo usuario → 400
        
        Scenario:
        - Usuario "admin" crea pool "POOL_TEST"
        - Usuario "admin" intenta crear otro pool con pool_id="POOL_TEST"
        
        Expected:
        - HTTP 400 (Conflict)
        - Mensaje: "Pool 'POOL_TEST' ya existe"
        
        This ensures pool_id uniqueness is scoped per user.
        """
        # Arrange
        pool_payload = {
            "pool_id": "POOL_TEST",
            "nombre": "Piscina de Prueba",
            "volumen_m3": 50.0,
            "activo": True
        }
        
        # Mock: usuario admin, pool ya existe en su cuenta
        mock_db = app.dependency_overrides[get_db]()
        mock_db.pools.find_one.return_value = {
            "pool_id": "POOL_TEST",
            "nombre": "Piscina Existente",
            "volumen_m3": 50.0,
            "username": "admin",
            "activo": True,
            "creado_en": datetime.utcnow()
        }
        
        # Mock get_current_user para retornar admin
        def mock_get_current_user(token: str = None):
            return {"username": "admin"}
        
        # Act
        with patch('routers.pools.get_db', return_value=mock_db), \
             patch('routers.pools.get_current_user', side_effect=mock_get_current_user):
            response = client.post("/api/v1/pools", json=pool_payload)
        
        # Assert
        assert response.status_code == 400, f"Expected 400, got {response.status_code}: {response.text}"
        assert "ya existe" in response.json()["detail"]

    def test_duplicate_pool_different_user_returns_201(self, app_with_mock_db):
        """
        CASO 2: Mismo pool_id, distinto usuario → 201 OK
        
        Scenario:
        - Usuario "admin" tiene pool con pool_id="POOL_SHARED"
        - Usuario "operator" intenta crear pool con pool_id="POOL_SHARED"
        
        Expected:
        - HTTP 201 (Created)
        - Se crea exitosamente para operator
        
        Pool uniqueness is per-user, so different users can have same pool_id.
        """
        # Arrange
        pool_payload = {
            "pool_id": "POOL_SHARED",
            "nombre": "Piscina del Operador",
            "volumen_m3": 75.0,
            "activo": True
        }
        
        # Mock: pool_id existe pero para otro usuario (admin)
        # Para operator, find_one retorna None
        mock_db = app.dependency_overrides[get_db]()
        mock_db.pools.find_one.return_value = None  # No existe para operator
        
        mock_insert_result = MagicMock()
        mock_insert_result.inserted_id = "ObjectId_999"
        mock_db.pools.insert_one.return_value = mock_insert_result
        
        # Mock get_current_user para retornar operator
        def mock_get_current_user(token: str = None):
            return {"username": "operator"}
        
        # Act
        with patch('routers.pools.get_db', return_value=mock_db), \
             patch('routers.pools.get_current_user', side_effect=mock_get_current_user):
            response = client.post("/api/v1/pools", json=pool_payload)
        
        # Assert
        assert response.status_code == 201, f"Expected 201, got {response.status_code}: {response.text}"
        data = response.json()
        assert data["ok"] is True
        assert data["pool_id"] == "POOL_SHARED"
        
        # Verificar que username fue agregado al documento
        call_args = mock_db.pools.insert_one.call_args
        inserted_doc = call_args[0][0]
        assert inserted_doc["username"] == "operator", "Document debe incluir username del usuario"

    def test_list_pools_only_current_user(self, app_with_mock_db):
        """
        CASO 3: GET lista pools solo retorna los del usuario autenticado
        
        Scenario:
        - Base de datos tiene 5 pools:
          * "admin" tiene 3 pools (POOL_A1, POOL_A2, POOL_A3)
          * "operator" tiene 2 pools (POOL_O1, POOL_O2)
        - Endpoint GET /api/v1/pools solicitado por "operator"
        
        Expected:
        - HTTP 200
        - Solo retorna 2 pools (los de operator)
        - No retorna los 3 pools de admin
        
        Filtro debería agregar {"username": "operator"} a la query.
        """
        # Arrange - Datos en BD (pools de múltiples usuarios)
        all_pools = [
            {
                "pool_id": "POOL_A1",
                "nombre": "Admin Pool 1",
                "volumen_m3": 50.0,
                "username": "admin",
                "activo": True,
                "creado_en": datetime.utcnow(),
                "settings": PoolSettings().model_dump()
            },
            {
                "pool_id": "POOL_A2",
                "nombre": "Admin Pool 2",
                "volumen_m3": 60.0,
                "username": "admin",
                "activo": True,
                "creado_en": datetime.utcnow(),
                "settings": PoolSettings().model_dump()
            },
            {
                "pool_id": "POOL_A3",
                "nombre": "Admin Pool 3",
                "volumen_m3": 45.0,
                "username": "admin",
                "activo": True,
                "creado_en": datetime.utcnow(),
                "settings": PoolSettings().model_dump()
            },
            {
                "pool_id": "POOL_O1",
                "nombre": "Operator Pool 1",
                "volumen_m3": 70.0,
                "username": "operator",
                "activo": True,
                "creado_en": datetime.utcnow(),
                "settings": PoolSettings().model_dump()
            },
            {
                "pool_id": "POOL_O2",
                "nombre": "Operator Pool 2",
                "volumen_m3": 80.0,
                "username": "operator",
                "activo": False,
                "creado_en": datetime.utcnow(),
                "settings": PoolSettings().model_dump()
            }
        ]
        
        # Mock find que simula filtro por usuario
        def mock_find(query, projection):
            # Simulamos el filtro: solo pools del usuario en query
            if "username" in query:
                filtered = [p for p in all_pools if p["username"] == query["username"]]
                return MagicMock(__iter__=lambda self: iter(filtered))
            return MagicMock(__iter__=lambda self: iter(all_pools))
        
        mock_db = app.dependency_overrides[get_db]()
        mock_db.pools.find.side_effect = mock_find
        
        # Mock get_current_user para retornar operator
        def mock_get_current_user(token: str = None):
            return {"username": "operator"}
        
        # Act
        with patch('routers.pools.get_db', return_value=mock_db), \
             patch('routers.pools.get_current_user', side_effect=mock_get_current_user):
            response = client.get("/api/v1/pools")
        
        # Assert
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        data = response.json()
        
        # Solo 2 pools (los de operator)
        assert data["total"] == 2, f"Expected 2 pools for 'operator', got {data['total']}"
        assert len(data["pools"]) == 2, f"Expected 2 pools in list, got {len(data['pools'])}"
        
        # Verificar que solo están los pools de operator
        pool_ids = [p["pool_id"] for p in data["pools"]]
        assert "POOL_O1" in pool_ids, "Must include POOL_O1 (operator's pool)"
        assert "POOL_O2" in pool_ids, "Must include POOL_O2 (operator's pool)"
        
        # Verificar que NO están los pools de admin
        assert "POOL_A1" not in pool_ids, "Must NOT include POOL_A1 (admin's pool)"
        assert "POOL_A2" not in pool_ids, "Must NOT include POOL_A2 (admin's pool)"
        assert "POOL_A3" not in pool_ids, "Must NOT include POOL_A3 (admin's pool)"
        
        # Verificar que find fue llamado con filtro por username
        mock_db.pools.find.assert_called()
        call_args = mock_db.pools.find.call_args
        query_filter = call_args[0][0]
        assert "username" in query_filter, "Query debe incluir filtro 'username'"
        assert query_filter["username"] == "operator", "Query debe filtrar por 'operator'"
=======
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
