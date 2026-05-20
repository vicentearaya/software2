"""
test_integration.py — Tests de integración para flujos auth + piscinas + estado
=================================================================================
Sprint 4: Valida flujos end-to-end entre múltiples endpoints.
Corre con: cd backend && python -m pytest tests/test_integration.py -v
"""

from unittest.mock import MagicMock, patch
import os
import pytest
from fastapi.testclient import TestClient
from passlib.context import CryptContext
from bson import ObjectId

# ── Patch de MongoDB ANTES de importar la app ──────────────────────────────
os.environ["MONGODB_URI"] = "mongodb://localhost"
os.environ["SECRET_KEY"] = "supersecretkey_for_testing_min_32_chars!!!"
os.environ["API_KEY"] = "dummy_api_key"

_mock_db = MagicMock()

with patch("pymongo.MongoClient", return_value=MagicMock(**{"__getitem__.return_value": _mock_db})):
    from main import app
    from routers.auth import get_current_user
    from db import get_db

client = TestClient(app)
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Fixtures ──────────────────────────────────────────────────────────────
@pytest.fixture(autouse=True)
def reset_mocks():
    """Limpia el estado del mock entre tests."""
    _mock_db.reset_mock()
    app.dependency_overrides.clear()
    app.dependency_overrides[get_db] = lambda: _mock_db
    yield
    app.dependency_overrides.clear()


# ══════════════════════════════════════════════════════════════════════════
# FLUJO 1: Auth — Register → Login → /auth/me
# ══════════════════════════════════════════════════════════════════════════

class TestAuthIntegrationFlow:
    """Flujo de integración: registro → login → consulta de perfil."""

    def test_register_then_login_flow(self):
        """
        Integración: Un usuario se registra y luego puede hacer login.
        Valida que el token del registro sea válido y que el login funcione
        con las mismas credenciales.
        """
        # ── 1. REGISTRO ──
        _mock_db["usuarios"].find_one.return_value = None
        _mock_db["usuarios"].insert_one.return_value = MagicMock(inserted_id="fake_id_reg")

        register_resp = client.post("/auth/register", json={
            "name": "Integración User",
            "username": "integ_user",
            "email": "integ@test.com",
            "password": "miPassword123"
        })

        assert register_resp.status_code == 201, f"Register falló: {register_resp.text}"
        reg_body = register_resp.json()
        assert reg_body["success"] is True
        assert "token" in reg_body
        token_from_register = reg_body["token"]
        assert len(token_from_register) > 20  # JWT tiene estructura real

        # ── 2. LOGIN con las mismas credenciales ──
        # auth.py usa _db a nivel de módulo (no DI), por lo que debemos
        # configurar el mock ANTES del request de login.
        hashed_pw = _pwd_context.hash("miPassword123")
        _mock_db["usuarios"].find_one.return_value = {
            "username": "integ_user",
            "email": "integ@test.com",
            "password": hashed_pw,
            "name": "Integración User"
        }

        login_resp = client.post("/auth/login", json={
            "username": "integ_user",
            "password": "miPassword123"
        })

        assert login_resp.status_code == 200, f"Login falló: {login_resp.text}"
        login_body = login_resp.json()
        assert "access_token" in login_body
        assert login_body["token_type"] == "bearer"

    def test_login_then_get_me(self):
        """
        Integración: Login → /auth/me retorna los datos del usuario.
        """
        hashed_pw = _pwd_context.hash("password456")
        _mock_db["usuarios"].find_one.return_value = {
            "username": "juan_tec",
            "email": "juan@pool.com",
            "password": hashed_pw,
            "name": "Juan Técnico"
        }

        # Login
        login_resp = client.post("/auth/login", json={
            "username": "juan_tec",
            "password": "password456"
        })
        assert login_resp.status_code == 200
        token = login_resp.json()["access_token"]

        # GET /auth/me con el token
        me_resp = client.get("/auth/me", headers={
            "Authorization": f"Bearer {token}"
        })
        assert me_resp.status_code == 200
        me_data = me_resp.json()
        assert me_data["username"] == "juan_tec"
        assert me_data["email"] == "juan@pool.com"
        assert me_data["name"] == "Juan Técnico"


# ══════════════════════════════════════════════════════════════════════════
# FLUJO 2: Piscinas CRUD — Crear → Listar → Actualizar → Eliminar
# ══════════════════════════════════════════════════════════════════════════

class TestPiscinasCrudFlow:
    """Flujo de integración: CRUD completo de piscinas del usuario."""

    def _auth_override(self):
        """Helper para inyectar usuario autenticado."""
        app.dependency_overrides[get_current_user] = lambda: {
            "username": "tecnico_crud",
            "name": "Técnico CRUD"
        }

    def test_create_and_list_piscina(self):
        """Integración: Crear una piscina y luego verificar que aparece en el listado."""
        self._auth_override()

        fake_oid = ObjectId()

        # Mock para create (usa DI: Depends(get_db))
        from db import get_db
        mock_db_local = MagicMock()
        mock_db_local.piscinas.insert_one.return_value = MagicMock(inserted_id=fake_oid)
        app.dependency_overrides[get_db] = lambda: mock_db_local

        # 1. CREAR
        create_resp = client.post("/piscinas", json={
            "nombre": "Piscina Integración",
            "volumen": 45.0,
            "tipo": "exterior",
            "ubicacion": "Patio trasero",
            "largo": 9.0,
            "ancho": 5.0,
            "profundidad": 1.0,
            "filtro": True
        })
        assert create_resp.status_code == 201, f"Create falló: {create_resp.text}"
        created = create_resp.json()
        assert created["nombre"] == "Piscina Integración"

        # 2. LISTAR
        mock_db_local.piscinas.find.return_value = [{
            "_id": fake_oid,
            "username": "tecnico_crud",
            "nombre": "Piscina Integración",
            "volumen": 45.0,
            "tipo": "exterior",
            "ubicacion": "Patio trasero",
            "largo": 9.0,
            "ancho": 5.0,
            "profundidad": 1.0,
            "filtro": True,
        }]

        list_resp = client.get("/piscinas")
        assert list_resp.status_code == 200
        pools = list_resp.json()
        assert len(pools) >= 1
        assert pools[0]["nombre"] == "Piscina Integración"

    def test_update_piscina(self):
        """Integración: Actualizar una piscina existente."""
        self._auth_override()

        fake_oid = ObjectId()

        from db import get_db
        mock_db_local = MagicMock()
        mock_db_local.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "tecnico_crud",
            "nombre": "Piscina Original",
            "volumen": 30.0,
            "tipo": "interior",
            "ubicacion": "",
            "largo": 6.0,
            "ancho": 5.0,
            "profundidad": 1.0,
            "filtro": True,
        }
        mock_db_local.piscinas.update_one.return_value = MagicMock(matched_count=1)
        app.dependency_overrides[get_db] = lambda: mock_db_local

        update_resp = client.put(f"/piscinas/{str(fake_oid)}", json={
            "nombre": "Piscina Renovada",
            "volumen": 35.0,
            "tipo": "interior",
            "ubicacion": "Gimnasio",
            "largo": 7.0,
            "ancho": 5.0,
            "profundidad": 1.0,
            "filtro": True
        })
        assert update_resp.status_code == 200
        updated = update_resp.json()
        assert updated["nombre"] == "Piscina Renovada"
        assert updated["volumen"] == 35.0

    def test_delete_piscina(self):
        """Integración: Eliminar una piscina y sus registros asociados."""
        self._auth_override()

        fake_oid = ObjectId()

        from db import get_db
        mock_db_local = MagicMock()
        mock_db_local.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "tecnico_crud",
            "nombre": "Piscina a Eliminar",
        }
        mock_db_local.piscinas.delete_one.return_value = MagicMock(deleted_count=1)
        mock_db_local.mantenimientos.delete_many.return_value = MagicMock(deleted_count=3)
        mock_db_local.lecturas.delete_many.return_value = MagicMock(deleted_count=5)
        app.dependency_overrides[get_db] = lambda: mock_db_local

        del_resp = client.delete(f"/piscinas/{str(fake_oid)}")
        assert del_resp.status_code == 200
        del_body = del_resp.json()
        assert del_body["ok"] is True


# ══════════════════════════════════════════════════════════════════════════
# FLUJO 3: Estado de piscina — Pool Status endpoint
# ══════════════════════════════════════════════════════════════════════════

class TestPoolStatusFlow:
    """Estado del agua vía GET /piscinas/{id}/status (JWT + misma lógica que el alias /api/v1/pools)."""

    def _status_auth(self):
        app.dependency_overrides[get_current_user] = lambda: {
            "username": "status_user",
            "name": "Usuario Estado",
        }

    def test_pool_status_with_sensor_data(self):
        """
        Integración: GET /piscinas/{id}/status cuando hay datos de sensor.
        Sensor: pH=7.5, cloro=2.0 → APTA
        """
        from db import get_db

        self._status_auth()

        fake_oid = ObjectId()
        mock_db_local = MagicMock()

        mock_db_local.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "status_user",
            "nombre": "Piscina Status Test",
            "volumen": 50.0,
        }
        mock_db_local.lecturas.find_one.return_value = {
            "pool_id": str(fake_oid),
            "ph": 7.5,
            "cloro": 2.0,
            "temperatura": 26.0,
            "timestamp": "2026-05-04T10:00:00Z",
        }
        mock_db_local.mantenimientos.find_one.return_value = None

        app.dependency_overrides[get_db] = lambda: mock_db_local

        resp = client.get(f"/piscinas/{str(fake_oid)}/status")
        assert resp.status_code == 200, f"Status falló: {resp.text}"
        data = resp.json()
        assert data["ok"] is True
        assert data["estado"] == "APTA"
        assert data["parametros"]["ph"]["valor"] == 7.5
        assert data["parametros"]["cloro"]["valor"] == 2.0

    def test_pool_status_not_apt(self):
        """
        Integración: GET /piscinas/{id}/status cuando pH está fuera de rango.
        Sensor: pH=5.0, cloro=0.3 → NO APTA
        """
        from db import get_db

        self._status_auth()

        fake_oid = ObjectId()
        mock_db_local = MagicMock()

        mock_db_local.piscinas.find_one.return_value = {
            "_id": fake_oid,
            "username": "status_user",
            "nombre": "Piscina Fuera Rango",
            "volumen": 30.0,
        }
        mock_db_local.lecturas.find_one.return_value = {
            "pool_id": str(fake_oid),
            "ph": 5.0,
            "cloro": 0.3,
            "temperatura": 35.0,
            "timestamp": "2026-05-04T10:00:00Z",
        }
        mock_db_local.mantenimientos.find_one.return_value = None

        app.dependency_overrides[get_db] = lambda: mock_db_local

        resp = client.get(f"/piscinas/{str(fake_oid)}/status")
        assert resp.status_code == 200
        data = resp.json()
        assert data["estado"] == "NO APTA"

    def test_pool_status_404_when_pool_not_found(self):
        """
        Integración: GET /piscinas/{id}/status retorna 404 si la piscina no existe o no es del usuario.
        """
        from db import get_db

        self._status_auth()

        mock_db_local = MagicMock()
        mock_db_local.piscinas.find_one.return_value = None

        app.dependency_overrides[get_db] = lambda: mock_db_local

        resp = client.get("/piscinas/nonexistent_id/status")
        assert resp.status_code == 404


# ══════════════════════════════════════════════════════════════════════════
# FLUJO 4: Mantenciones con auth — Crear mantenimiento y consultar historial
# ══════════════════════════════════════════════════════════════════════════

class TestMantencionesIntegrationFlow:
    """Flujo de integración: crear mantención autenticada → consultar historial."""

    def test_create_then_list_mantenciones(self):
        """
        Integración: POST /mantenciones/ → GET /mantenciones/
        Verifica que el registro creado aparece en el historial.
        """
        app.dependency_overrides[get_current_user] = lambda: {
            "username": "tecnico_integ",
            "name": "Técnico Integración",
        }

        # Mock de insert
        _mock_db["mantenciones"].insert_one.return_value = MagicMock(
            inserted_id="fake_mant_id"
        )

        # 1. CREAR
        create_resp = client.post("/mantenciones/", json={
            "id_piscina": "PISC-INTEG-001",
            "productos": ["Cloro granulado", "Elevador de pH"],
            "cantidades": ["500g", "200g"],
            "ph": 7.0,
            "cloro": 0.8,
            "temperatura": 25.0
        })
        assert create_resp.status_code == 201
        created = create_resp.json()
        assert created["username"] == "tecnico_integ"
        assert created["ph"] == 7.0

        # 2. CONSULTAR HISTORIAL
        _mock_db["mantenciones"].find.return_value.sort.return_value = [{
            "id_piscina": "PISC-INTEG-001",
            "productos": ["Cloro granulado", "Elevador de pH"],
            "cantidades": ["500g", "200g"],
            "fecha": "2026-05-04T12:00:00+00:00",
            "username": "tecnico_integ",
            "ph": 7.0,
            "cloro": 0.8,
            "temperatura": 25.0,
            "creado_en": "2026-05-04T12:00:05+00:00"
        }]

        list_resp = client.get("/mantenciones/")
        assert list_resp.status_code == 200
        historial = list_resp.json()
        assert len(historial) >= 1
        assert historial[0]["id_piscina"] == "PISC-INTEG-001"
