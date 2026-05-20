# 📋 **MANUAL DE PRUEBAS — Sprint 4 CleanPool**

**Proyecto:** CleanPool - Monitoreo IoT de Piscinas  
**Hito:** Sprint 4 - Filtros, Inventario & Tarjeta Warning  
**Fecha:** 04 de Mayo, 2026  
**Estado:** Listo para Demo  

---

## **🎯 Objetivo del Manual**

Este documento guía al evaluador a través de los **casos de prueba** que validan:
- ✅ Autenticación JWT (login, registro, /auth/me)
- ✅ CRUD de Piscinas del usuario (/piscinas)
- ✅ Estado de piscina con prioridad sensor > manual (`GET /piscinas/{id}/status` con JWT; alias legacy `GET /api/v1/pools/{id}/status`)
- ✅ Mantenciones con historial (/mantenciones)
- ✅ Ingesta IoT con X-API-KEY (/api/v1/lectura)
- ✅ Evaluación de sensores (/lecturas/estado)
- ✅ Calculadora de tratamiento (/piscinas/{id}/tratamiento)

**Tiempo estimado:** 15-20 minutos

---

## **🚀 PREPARACIÓN PREVIA (5 minutos)**

### **Paso 1: Iniciar el Backend**

```powershell
cd backend
uvicorn main:app --reload
```

**Salida esperada:**
```
INFO:     Application startup complete
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### **Paso 2: Abrir Swagger UI**

En navegador:
```
http://localhost:8000/docs
```

Deberías ver la interfaz interactiva de FastAPI con todos los endpoints listados.

### **Paso 3: Correr tests automatizados**

```powershell
cd backend
python -m pytest tests/ -v --tb=short
```

**Salida esperada:** Todos los tests PASSED.

En GitHub Actions, el workflow **CI** (`.github/workflows/ci.yml`) ejecuta los mismos tests en push y pull request a la rama `main`.

---

## **📍 MAPA DE ENDPOINTS VIGENTES**

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/` | No | Health check |
| `POST` | `/auth/register` | No | Registro de usuario |
| `POST` | `/auth/login` | No | Login con JWT |
| `GET` | `/auth/me` | JWT | Datos del usuario autenticado |
| `GET` | `/piscinas` | JWT | Listar piscinas del usuario |
| `POST` | `/piscinas` | JWT | Crear piscina |
| `PUT` | `/piscinas/{pool_id}` | JWT | Actualizar piscina |
| `DELETE` | `/piscinas/{pool_id}` | JWT | Eliminar piscina y datos asociados |
| `GET` | `/piscinas/{pool_id}/status` | JWT | Estado del agua (sensor > manual); **vía oficial de la app** |
| `POST` | `/piscinas/{pool_id}/tratamiento` | JWT | Calcular y guardar tratamiento manual |
| `POST` | `/mantenciones/` | JWT | Registrar mantención |
| `GET` | `/mantenciones/` | JWT | Historial de mantenciones del usuario |
| `POST` | `/api/v1/lectura` | X-API-KEY | Ingestar lectura de sensores IoT |
| `GET` | `/lecturas/estado` | No | Estado evaluado de sensores |
| `POST` | `/api/v1/pools` | No | Crear pool (colección `pools`, configuración legacy) |
| `GET` | `/api/v1/pools` | No | Listar pools (legacy) |
| `GET` | `/api/v1/pools/{pool_id}` | No | Detalle de pool (legacy) |
| `PUT` | `/api/v1/pools/{pool_id}` | No | Actualizar pool (legacy) |
| `DELETE` | `/api/v1/pools/{pool_id}` | No | Eliminar pool (legacy) |
| `GET` | `/api/v1/pools/{pool_id}/status` | No | Mismo cálculo que `/piscinas/.../status` (sin comprobar propietario; preferir ruta con JWT) |

---

## **✅ CASO 1: Health Check**

**Endpoint:** `GET /`

```bash
curl http://localhost:8000/
```

**Resultado esperado:**
```json
{"message": "CleanPool API funcionando"}
```

✅ Status 200 → PASA

---

## **✅ CASO 2: Registro de Usuario**

**Endpoint:** `POST /auth/register`

**Payload:**
```json
{
  "name": "Juan Técnico",
  "username": "juan_tec",
  "email": "juan@cleanpool.cl",
  "password": "miPassword123"
}
```

**Resultado esperado (201):**
```json
{
  "success": true,
  "token": "eyJhbGciOi...",
  "user": {
    "name": "Juan Técnico",
    "username": "juan_tec",
    "email": "juan@cleanpool.cl"
  }
}
```

**Caso duplicado (400):**
```json
{"detail": "El correo o nombre de usuario ya está registrado."}
```

---

## **✅ CASO 3: Login**

**Endpoint:** `POST /auth/login`

**Payload:**
```json
{
  "username": "juan_tec",
  "password": "miPassword123"
}
```

**Resultado esperado (200):**
```json
{
  "access_token": "eyJhbGciOi...",
  "token_type": "bearer"
}
```

**Credenciales incorrectas (401):**
```json
{"detail": "Credenciales incorrectas."}
```

---

## **✅ CASO 4: Datos del Usuario Autenticado**

**Endpoint:** `GET /auth/me`  
**Header:** `Authorization: Bearer <token>`

**Resultado esperado (200):**
```json
{
  "username": "juan_tec",
  "name": "Juan Técnico",
  "email": "juan@cleanpool.cl"
}
```

---

## **✅ CASO 5: CRUD de Piscinas**

### 5a. Crear Piscina
**Endpoint:** `POST /piscinas`  
**Header:** `Authorization: Bearer <token>`

**Payload:**
```json
{
  "nombre": "Piscina Principal",
  "volumen": 45.0,
  "tipo": "exterior",
  "ubicacion": "Patio trasero",
  "largo": 9.0,
  "ancho": 5.0,
  "profundidad": 1.0,
  "filtro": true
}
```

**Resultado esperado (201):**
```json
{
  "id": "682...",
  "username": "juan_tec",
  "nombre": "Piscina Principal",
  "volumen": 45.0,
  "tipo": "exterior",
  "ubicacion": "Patio trasero",
  "largo": 9.0,
  "ancho": 5.0,
  "profundidad": 1.0,
  "filtro": true
}
```

### 5b. Listar Piscinas
**Endpoint:** `GET /piscinas`  
**Resultado esperado (200):** Array con las piscinas del usuario.

### 5c. Actualizar Piscina
**Endpoint:** `PUT /piscinas/{pool_id}`  
**Payload:** Mismo schema que la creación con datos actualizados.

### 5d. Eliminar Piscina
**Endpoint:** `DELETE /piscinas/{pool_id}`  
**Resultado esperado (200):**
```json
{"ok": true, "message": "Piscina eliminada correctamente"}
```

---

## **✅ CASO 6: Tratamiento Manual (Calculadora)**

**Endpoint:** `POST /piscinas/{pool_id}/tratamiento`  
**Header:** `Authorization: Bearer <token>`

**Payload:**
```json
{
  "ph": 6.5,
  "cloro": 0.4
}
```

**Resultado esperado (201):**
```json
{
  "ok": true,
  "mensaje": "Mantenimiento calculado y guardado exitosamente.",
  "tratamiento": [
    {
      "producto": "Elevador de pH (carbonato de sodio)",
      "cantidad": 506.2,
      "unidad": "gr",
      "instrucciones": "Paso 1: Aplicar en múltiples dosis..."
    },
    {
      "producto": "Cloro granulado",
      "cantidad": 800.0,
      "unidad": "gr",
      "instrucciones": "Paso 2: Aplicar dosis completa..."
    }
  ]
}
```

---

## **✅ CASO 7: Mantenciones**

### 7a. Crear Mantención
**Endpoint:** `POST /mantenciones/`  
**Header:** `Authorization: Bearer <token>`

**Payload:**
```json
{
  "id_piscina": "Piscina Principal",
  "productos": ["Cloro Triple Acción", "Clarificador"],
  "cantidades": ["1kg", "500ml"],
  "ph": 7.4,
  "cloro": 1.5,
  "temperatura": 27.0
}
```

**Resultado esperado (201):** Objeto Mantencion con `username` del JWT.

### 7b. Historial
**Endpoint:** `GET /mantenciones/`  
**Resultado esperado (200):** Array ordenado por fecha DESC.

### 7c. Sin autenticación
**Endpoint:** `GET /mantenciones/` (sin header Authorization)  
**Resultado esperado:** `401 Unauthorized`

---

## **✅ CASO 8: Ingesta IoT (X-API-KEY)**

**Endpoint:** `POST /api/v1/lectura`  
**Header:** `X-API-KEY: <valor de API_KEY en .env>`

**Payload:**
```json
{
  "pool_id": "piscina_test_01",
  "ph": 7.5,
  "cloro": 2.0,
  "temperatura": 26.0,
  "conductividad": 1500.0
}
```

**Sin API Key (403):**
```json
{"detail": "Forbidden"}
```

**Con API Key válida (200):**
```json
{"ok": true, "id": "507f1f77..."}
```

---

## **✅ CASO 9: Estado de Piscina**

**Vía oficial (app Flutter):** `GET /piscinas/{pool_id}/status`  
**Header:** `Authorization: Bearer <JWT>`  
Comprueba que la piscina pertenezca al usuario y devuelve el mismo JSON que el alias legacy.

**Alias legacy (sin comprobar propietario):** `GET /api/v1/pools/{pool_id}/status`

**Resultado esperado (200) — Piscina APTA:**
```json
{
  "ok": true,
  "pool_id": "682...",
  "estado": "APTA",
  "parametros": {
    "ph": {"valor": 7.5, "estado": "NORMAL", "fuente": "sensor"},
    "cloro": {"valor": 2.0, "estado": "NORMAL", "fuente": "sensor"},
    "temperatura": {"valor": 26.0, "estado": "NORMAL", "fuente": "manual"}
  }
}
```

**Resultado — Piscina NO APTA:**
```json
{
  "ok": true,
  "pool_id": "682...",
  "estado": "NO APTA",
  "parametros": {
    "ph": {"valor": 5.0, "estado": "BAJO", "fuente": "sensor"},
    "cloro": {"valor": 0.3, "estado": "BAJO", "fuente": "sensor"},
    "temperatura": {"valor": 35.0, "estado": "ALTO", "fuente": "sensor"}
  }
}
```

**Piscina inexistente o no del usuario (404):**
```json
{"detail": "Piscina no encontrada o no pertenece a tu cuenta."}
```

---

## **✅ CASO 10: Evaluación Legacy de Sensores**

**Endpoint:** `GET /lecturas/estado?pool_id=piscina_test_01`

**Resultado esperado (200):**
```json
{
  "piscina_apta": true,
  "sensores_criticos": [],
  "motivo": "Piscina en condiciones APTAS para usar...",
  "detalle_sensores": {
    "ph": {"valor": 7.5, "unidad": "pH", "estado": "OPTIMO", "mensaje": "pH en rango óptimo."},
    "cloro": {"valor": 2.0, "unidad": "ppm", "estado": "OPTIMO", "mensaje": "Cloro en nivel seguro."},
    "temperatura": {"valor": 26.0, "unidad": "°C", "estado": "OPTIMO", "mensaje": "Temperatura dentro del rango confortable."},
    "conductividad": {"valor": 1500.0, "unidad": "µS/cm", "estado": "OPTIMO", "mensaje": "Conductividad en nivel aceptable."}
  },
  "tratamiento": [...]
}
```

---

## **📊 Tabla Resumen de Pruebas**

| Caso | Endpoint | Entrada | Salida Esperada | Pass/Fail |
|------|----------|---------|-----------------|-----------|
| 1 | GET / | — | 200 + message | ✅ |
| 2 | POST /auth/register | name+username+email+password | 201 + token | ✅ |
| 3 | POST /auth/login | username+password | 200 + access_token | ✅ |
| 4 | GET /auth/me | JWT header | 200 + user data | ✅ |
| 5a | POST /piscinas | JWT + pool data | 201 + PiscinaOut | ✅ |
| 5b | GET /piscinas | JWT | 200 + lista | ✅ |
| 5c | PUT /piscinas/{id} | JWT + updated data | 200 + PiscinaOut | ✅ |
| 5d | DELETE /piscinas/{id} | JWT | 200 + ok | ✅ |
| 6 | POST /piscinas/{id}/tratamiento | JWT + ph + cloro | 201 + tratamiento | ✅ |
| 7a | POST /mantenciones/ | JWT + MantencionIn | 201 + Mantencion | ✅ |
| 7b | GET /mantenciones/ | JWT | 200 + lista | ✅ |
| 7c | GET /mantenciones/ | Sin JWT | 401 | ✅ |
| 8 | POST /api/v1/lectura | X-API-KEY + LecturaIn | 200 + ok | ✅ |
| 9 | GET /piscinas/{id}/status | JWT + pool_id | 200 + estado | ✅ |
| 10 | GET /lecturas/estado | pool_id query | 200 + StatusGlobalResponse | ✅ |

---

## **🧪 Tests Automatizados**

Los tests automatizados se encuentran en `backend/tests/` y cubren:

| Archivo | Cobertura |
|---------|-----------|
| `test_api.py` | Health check, readings, auth login/register |
| `test_integration.py` | Flujos auth→me, CRUD piscinas, pool status, mantenciones |
| `test_mantenciones.py` | POST/GET mantenciones, validación Pydantic, auth |
| `test_pools.py` | CRUD pools con settings default y custom |
| `test_status_service.py` | Aptitud global (apta, no apta, edge cases) |
| `test_services_calculator.py` | Cálculo de dosis químicas |
| `test_config_pool.py` | Evaluación de sensores por rango |
| `test_config_settings.py` | Validación de configuración Pydantic |
| `test_device_bindings_unit.py` | Vinculación de dispositivos |
| `test_ingesta_unit.py` | Ingesta de lecturas IoT |

**Ejecutar todos:**
```powershell
cd backend
python -m pytest tests/ -v
```

**Ejecutar uno específico:**
```powershell
cd backend
python -m pytest tests/test_integration.py -v
```

---

## **🔄 CI/CD: Ejecución Automática**

Los tests se ejecutan automáticamente en GitHub Actions en cada push a `main`.  
Workflow: `.github/workflows/main_software2-backend.yml`

El paso `Run backend tests` se ejecuta antes del despliegue a Azure.  
Si algún test falla, el deploy se cancela automáticamente.

---

**Documento Actualizado:** 04-MAY-2026  
**Status:** ✅ LISTO PARA DEMO  
**Esperado:** 0 fallas en pruebas  
