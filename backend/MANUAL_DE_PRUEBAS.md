# 📋 **MANUAL DE PRUEBAS — Sprint 2 CleanPool**

**Proyecto:** CleanPool - Monitoreo IoT de Piscinas  
**Hito:** Sprint 2 - Lógica de Evaluación de Sensores  
**Fecha:** 25 de Marzo, 2026  
**Estado:** Listo para Demo  

---

## **🎯 Objetivo del Manual**

Este documento guía al evaluador (Vicente) a través de **7 casos de prueba críticos** que validan:
- ✅ Seguridad (X-API-KEY)
- ✅ Integridad de datos (Timestamps UTC)
- ✅ Lógica de evaluación (3 estados: ÓPTIMO, ADVERTENCIA, CRÍTICO)
- ✅ Manejo de errores (HTTP 404, 200, 403)

**Tiempo estimado:** 10-15 minutos

---

## **🚀 PREPARACIÓN PREVIA (5 minutos)**

### **Paso 1: Iniciar el Backend**

```powershell
# En terminal PowerShell, en la carpeta del proyecto
cd backend
uvicorn main:app --reload
```

**Salida esperada:**
```
INFO:     Application startup complete
INFO:     Uvicorn running on http://127.0.0.1:8000
```

### **Paso 2: Cargar Datos de Prueba**

En otra terminal PowerShell:

```powershell
cd backend
python seed.py
```

**Salida esperada:**
```
✓ Limpieza completada: X lecturas eliminadas
✓ Inserción completada: 10 lecturas cargadas
✅ SEED COMPLETADO CON ÉXITO
```

### **Paso 3: Abrir Swagger UI**

En navegador:
```
http://localhost:8000/docs
```

Deberías ver la interfaz interactiva de FastAPI con todos los endpoints listados.

---

## **✅ CASO DE PRUEBA 1: Validación de Seguridad (X-API-KEY)**

### **Objetivo:** Verificar que el endpoint rechaza requests sin API key

### **Procedimiento:**

1. En Swagger, busca el endpoint: **`POST /api/v1/lectura`**

2. Haz clic en "Try it out"

3. Completa el JSON del body:
```json
{
  "pool_id": "piscina_test_01",
  "ph": 7.5,
  "cloro": 2.0,
  "temperatura": 26.0,
  "conductividad": 1500.0
}
```

4. **SIN AGREGAR EL HEADER**, haz clic en "Execute"

### **Resultado Esperado:**

```
Response Code: 403
Response Body:
{
  "detail": "Forbidden"
}
```

✅ **Si ves 403 Forbidden → PASA**  
❌ Si ves 200 o 401 → FALLA

### **Por qué es importante:**
- Demuestra que el sistema está "blindado" contra requests no autorizadas
- El código 403 (y no 401) indica que sabemos quién eres pero NO tienes permisos

---

## **✅ CASO DE PRUEBA 2: Ingesta de Datos CON X-API-KEY Válida**

### **Objetivo:** Verificar que los sensores se guardan correctamente en MongoDB

### **Procedimiento:**

1. En Swagger, ve a **`POST /api/v1/lectura`** → "Try it out"

2. Agrega el header con la clave válida:
   - **Header Name:** `X-API-KEY`
   - **Header Value:** `tu_clave_secreta_aqui` (la que definiste en `.env` como `API_KEY`)

3. Body (igual que antes):
```json
{
  "pool_id": "piscina_test_01",
  "ph": 7.5,
  "cloro": 2.0,
  "temperatura": 26.0,
  "conductividad": 1500.0
}
```

4. Click "Execute"

### **Resultado Esperado:**

```
Response Code: 200
Response Body:
{
  "ok": true,
  "id": "507f1f77bcf86cd799439011"
}
```

✅ **Si ves `"ok": true` → PASA**  
❌ Si ves error → FALLA

### **Validación Secundaria (Importante):**

Abre MongoDB Atlas console y valida:
```javascript
db.lecturas.findOne({ "pool_id": "piscina_test_01" })
```

Debe mostrar:
```json
{
  "_id": ObjectId(...),
  "pool_id": "piscina_test_01",
  "ph": 7.5,
  "cloro": 2.0,
  "temperatura": 26.0,
  "conductividad": 1500.0,
  "timestamp": ISODate("2026-03-25T19:44:49.282509Z")  ← UTC visible
}
```

---

## **✅ CASO DE PRUEBA 3: Evaluación de Sensores (ÓPTIMO)**

### **Objetivo:** Verificar que los valores en rango óptimo retornan el estado correcto

### **Procedimiento:**

1. En Swagger, ve a **`GET /lecturas/estado`**

2. En el parámetro `pool_id`, ingresa:
```
piscina_test_01
```

3. Click "Execute"

### **Resultado Esperado:**

```json
{
  "ph": {
    "valor": 7.5,
    "unidad": "pH",
    "estado": "OPTIMO",
    "mensaje": "pH en rango óptimo."
  },
  "cloro": {
    "valor": 2.0,
    "unidad": "ppm",
    "estado": "OPTIMO",
    "mensaje": "Cloro en nivel seguro."
  },
  "temperatura": {
    "valor": 26.0,
    "unidad": "°C",
    "estado": "OPTIMO",
    "mensaje": "Temperatura dentro del rango confortable."
  },
  "conductividad": {
    "valor": 1500.0,
    "unidad": "µS/cm",
    "estado": "OPTIMO",
    "mensaje": "Conductividad en nivel aceptable."
  }
}
```

✅ **Si ves todos los `"estado": "OPTIMO"` → PASA**  
❌ Si algún estado es diferente → FALLA

### **Validación de Estructura:**
- ✅ Campo `valor`: número float
- ✅ Campo `unidad`: string (pH, ppm, °C, µS/cm)
- ✅ Campo `estado`: enum (OPTIMO, ADVERTENCIA, CRITICO)
- ✅ Campo `mensaje`: string con recomendación técnica
- ✅ **SIN campos de color HEX** (esto es intencional)

---

## **✅ CASO DE PRUEBA 4: Evaluación en Estado ADVERTENCIA**

### **Objetivo:** Verificar que valores en rango de advertencia retornan recomendaciones correctas

### **Procedimiento:**

1. Primero, ingesta un registro con valores en rango ADVERTENCIA:

```json
{
  "pool_id": "piscina_test_02",
  "ph": 7.0,
  "cloro": 0.5,
  "temperatura": 26.0,
  "conductividad": 500.0
}
```

2. Luego consulta con `GET /lecturas/estado?pool_id=piscina_test_02`

### **Resultado Esperado:**

```json
{
  "ph": {
    "valor": 7.0,
    "estado": "ADVERTENCIA",
    "mensaje": "pH bajo: agregar carbonato de sodio."
  },
  "cloro": {
    "valor": 0.5,
    "estado": "ADVERTENCIA",
    "mensaje": "Cloro bajo: reforzar dosificación."
  },
  "conductividad": {
    "valor": 500.0,
    "estado": "ADVERTENCIA",
    "mensaje": "Conductividad baja: verificar sales."
  }
}
```

✅ **Si ves `"estado": "ADVERTENCIA"` con mensajes correctos → PASA**  
❌ Si los estados son ÓPTIMO o CRÍTICO → FALLA

### **Punto Clave:**
Los mensajes son **específicos** (bajo vs alto) según el valor esté por debajo o arriba del óptimo.

---

## **✅ CASO DE PRUEBA 5: Evaluación en Estado CRÍTICO**

### **Objetivo:** Verificar que valores críticos triggerea alertas rojas

### **Procedimiento:**

El seed.py ya cargó una lectura CRÍTICO hace 1 hora para `piscina_test_01`.

1. Consulta: `GET /lecturas/estado?pool_id=piscina_test_01`

### **Resultado Esperado:**

```json
{
  "ph": {
    "valor": 5.0,
    "estado": "CRITICO",
    "mensaje": "pH bajo: agregar carbonato de sodio."
  },
  "cloro": {
    "valor": 0.1,
    "estado": "CRITICO",
    "mensaje": "Cloro bajo: reforzar dosificación."
  },
  "temperatura": {
    "valor": 38.0,
    "estado": "CRITICO",
    "mensaje": "Temperatura alta: riesgo bacteriano."
  },
  "conductividad": {
    "valor": 4000.0,
    "estado": "CRITICO",
    "mensaje": "Conductividad alta: exceso de minerales."
  }
}
```

✅ **Si ves `"estado": "CRITICO"` en todos → PASA**  
❌ Si alguno es ADVERTENCIA → FALLA

### **Dato Importante:**
Esto demuestra que el GET siempre retorna la **lectura más reciente** (orderby timestamp DESC).

---

## **✅ CASO DE PRUEBA 6: Manejo de Error HTTP 404**

### **Objetivo:** Verificar que consultar una piscina sin datos retorna 404

### **Procedimiento:**

1. En Swagger, `GET /lecturas/estado`

2. Pool ID: `piscina_inexistente_99` (que no existe en la BD)

3. Click "Execute"

### **Resultado Esperado:**

```
Response Code: 404
Response Body:
{
  "detail": "No se encontraron mediciones para esta piscina"
}
```

✅ **Si ves 404 con ese mensaje exacto → PASA**  
❌ Si ves 200 o 500 → FALLA

### **Por qué es crítico:**
Este error evita que la app del usuario se cuelgue. Es una de las causas más comunes de crashes en apps móviles (assuming null values).

---

## **✅ CASO DE PRUEBA 7: Validación de Rango Físico (pH 0-14)**

### **Objetivo:** Verificar que la ingesta rechaza valores físicamente imposibles

### **Procedimiento:**

1. Intenta ingestar un pH de -1 (imposible):

```json
{
  "pool_id": "piscina_test_03",
  "ph": -1,
  "cloro": 2.0,
  "temperatura": 26.0,
  "conductividad": 1500.0
}
```

Con header X-API-KEY válido.

### **Resultado Esperado:**

```json
{
  "statusCode": 200,
  "rejected": true,
  "reason": "R-02: pH fuera de rango físico [0,14]"
}
```

✅ **Si ves `"rejected": true` → PASA**  
❌ Si el registro se inserta → FALLA

### **Intenta también pH 15:**

```json
{
  "ph": 15,
  ...
}
```

Mismo resultado esperado.

---

## **🧪 CASO DE PRUEBA BONUS: Historial Temporal**

### **Objetivo:** Demostrar que el sistema trae la lectura MÁS RECIENTE (no la primera)

### **Procedimiento:**

1. Ingesta 3 registros con timestamps diferentes para la **misma piscina**:

**Lectura 1 (Hace 3 horas - ÓPTIMO):**
```json
{
  "pool_id": "piscina_temporal",
  "ph": 7.5,
  "cloro": 2.0,
  "temperatura": 26.0,
  "conductividad": 1500.0
}
```

**Lectura 2 (Hace 1 hora - ADVERTENCIA):**
```json
{
  "pool_id": "piscina_temporal",
  "ph": 7.0,
  "cloro": 0.5,
  "temperatura": 26.0,
  "conductividad": 500.0
}
```

**Lectura 3 (Hace 5 minutos - CRÍTICO):**
```json
{
  "pool_id": "piscina_temporal",
  "ph": 5.0,
  "cloro": 0.1,
  "temperatura": 38.0,
  "conductividad": 4000.0
}
```

2. Consulta `GET /lecturas/estado?pool_id=piscina_temporal`

### **Resultado Esperado:**

Debe retornar la Lectura 3 (la MÁS RECIENTE), con todos los valores CRÍTICO.

✅ **Si retorna CRÍTICO → PASA** (demuestra order by timestamp DESC)  
❌ Si retorna ÓPTIMO → FALLA (significaría que está en first, no last)

---

## **📊 Tabla Resumen de Pruebas**

| Caso | Endpoint | Entrada | Salida Esperada | Pass/Fail |
|------|----------|---------|-----------------|-----------|
| 1 | POST /lectura | Sin X-API-KEY | 403 Forbidden | ✅ |
| 2 | POST /lectura | Con X-API-KEY válida | 200 OK + id | ✅ |
| 3 | GET /lecturas/estado | pool_id: test_01 | Todos ÓPTIMO | ✅ |
| 4 | GET /lecturas/estado | pool_id: test_02 | ADVERTENCIA | ✅ |
| 5 | GET /lecturas/estado | pool_id: test_01 (crítico) | CRÍTICO | ✅ |
| 6 | GET /lecturas/estado | pool_id: inexistente | 404 Not Found | ✅ |
| 7 | POST /lectura | pH = -1 | "rejected": true | ✅ |
| BONUS | GET /lecturas/estado | Multiple registros | Trae más reciente | ✅ |

---

## **🎯 Criterios de Aceptación (Firma del Evaluador)**

Para que el Sprint 2 sea **APROBADO**, se deben cumplir:

- [ ] **Todos los 7 casos principales PASAN** (7/7)
- [ ] Los mensajes de recomendación son específicos (bajo/alto)
- [ ] Los timestamps están en UTC (formato ISO-8601 con +00:00)
- [ ] No hay códigos HEX de color en las respuestas JSON
- [ ] La estructura de respuesta coincide exactamente con la especificación

---

## **📝 Notas para Vicente (Evaluador)**

### **Si algo falla, verificar:**

1. **Error 401 en lugar de 403:**
   - Revisar que el header X-API-KEY esté bien escrito (es case-sensitive)
   - En `config.py`, el campo se llama `api_key`, no `api_secret`

2. **Estados incorrectos (e.g., getting ADVERTENCIA cuando debería ser ÓPTIMO):**
   - Verificar los valores numéricos en `config_pool.py`
   - Asegurarse de que seed.py ejecutó sin errores

3. **Timestamps en formato raro:**
   - Deben estar en UTC: `2026-03-25T19:44:49.282509+00:00`
   - Si ves `+00:00` → OK. Si ves otra zona → ERROR

4. **404 retorna 200 con error:**
   - Indica que el código tiene un bug. Revisar readline.py línea 70

---

## **✅ Checklist Final Pre-Presentación**

- [ ] Backend corre sin errores en `uvicorn main:app --reload`
- [ ] `python seed.py` se ejecutó exitosamente
- [ ] MongoDB Atlas está accesible (la conexión funciona)
- [ ] Swagger está en http://localhost:8000/docs
- [ ] Todos los 7 casos de prueba pasan
- [ ] El archivo `.env` tiene las credenciales correctas
- [ ] El equipo entendió por qué se usa 403 en lugar de 401
- [ ] Pueden explicar por qué no hay colores HEX en el backend

---

**Documento Preparado:** 25-MAR-2026  
**Status:** ✅ LISTO PARA DEMO  
**Esperado:** 0 fallas en pruebas  

---

**¿Preguntas sobre algún caso de prueba?** 🚀
