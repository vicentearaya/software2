# Sprint 2: Implementación de Lógica de Evaluación de Sensores

## ✅ COMPLETADO

### 1. Creado: `backend/core/config_pool.py`
- **Enum `EstadoAgua`**: Define 3 estados (OPTIMO, ADVERTENCIA, CRITICO)
- **Dataclass `RangoSensor`**: Encapsula rangos y mensajes para cada sensor
- **Dict `RANGOS`**: Configuración para 4 sensores:
  - **pH**: 7.2-7.8 óptimo, 6.8-8.2 advertencia
  - **Cloro (ppm)**: 1.0-3.0 óptimo, 0.5-5.0 advertencia
  - **Temperatura (°C)**: 24.0-30.0 óptimo, 20.0-34.0 advertencia
  - **Conductividad (µS/cm)**: 1000-2000 óptimo, 500-3000 advertencia
- **Función `evaluar_sensor(clave, valor)`**: 
  - Retorna `{"valor": X, "unidad": "...", "estado": EstadoAgua, "mensaje": "..."}`

### 2. Actualizado: `backend/routers/ingesta.py`
**Cambios:**
- ❌ Status 401 → ✅ Status 403 Forbidden para API key inválida
- ➕ Nuevo modelo `LecturaIn` con campos: `pool_id, ph, cloro, temperatura, conductividad`
- ✅ Mantiene modelo compatible `LecturaInCompat` para legacy

**Endpoints:**
- `POST /api/v1/lectura` (NUEVO)
  - Valida X-API-KEY contra `settings.api_key`
  - Agrega timestamp UTC automático
  - Guarda en MongoDB colección "lecturas"
  - Retorna: `{"ok": true, "id": "<ObjectId>"}`
  
- `POST /api/v1/sensor/data` (LEGACY - Mantenido para compatibilidad)
  - Mismo flujo pero con modelo anterior
  - Retorna formato antiguo para no romper clientes existentes

### 3. Actualizado: `backend/routers/readings.py`
**Cambios:**
- ✅ Importa `evaluar_sensor` desde `core.config_pool`
- 📦 Mantiene función legacy `_calcular_estado()` marcada como DEPRECADA
- ➕ Nuevo endpoint `GET /lecturas/estado`

**Nuevos Endpoints:**
- `GET /lecturas/estado?pool_id=xxx` (NUEVO - Principal)
  - Query param: `pool_id` (requerido)
  - Obtiene última lectura para ese pool_id
  - Evalúa cada sensor con mensajes contextuales
  - Retorna estructura completa con unidades y estados
  
- `GET /readings?id_piscina=xxx` (LEGACY - Depuesto)
  - Mantiene param opcional `id_piscina`
  - Marca como "deprecated=True" en OpenAPI

## 📊 Validación Ejecutada

✅ Todos los casos de evaluación de sensores validados:
- pH en estado CRÍTICO, ADVERTENCIA, ÓPTIMO
- Cloro en todos los rangos
- Temperatura en condiciones extremas
- Conductividad con valores altos/bajos

## 🔒 Seguridad
- ✅ Validación de X-API-KEY contra variable de entorno
- ✅ Respuesta 403 Forbidden en caso de rechazo
- ✅ Timestamps UTC en servidor (no confía en cliente)
- ✅ Inserción directa en MongoDB sin evaluación en POST
  (La evaluación solo ocurre en GET /lecturas/estado)

## 📂 Estructura Final
```
backend/
├── core/
│   ├── __init__.py
│   └── config_pool.py         ← NUEVO
├── routers/
│   ├── ingesta.py             ← ACTUALIZADO
│   └── readings.py            ← ACTUALIZADO
├── main.py                     ← Sin cambios
├── config.py                   ← Sin cambios
├── db.py                       ← Sin cambios
└── ...
```

## 🚀 Próximos Pasos del Sprint 2
- [ ] Actualizar documentación OpenAPI/Swagger
- [ ] Tests unitarios para `evaluar_sensor()`
- [ ] Integración con frontend Flutter para GET /lecturas/estado
- [ ] Logs de auditoria en ingesta de datos
