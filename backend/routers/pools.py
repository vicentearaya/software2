"""
pools.py — Endpoints CRUD para Gestión de Piscinas (Pools)

Proporciona operaciones de creación, lectura, actualización y eliminación
de configuraciones de piscinas en MongoDB. Critical para que el módulo
de calculadora de dosis químicas funcione correctamente.

El volumen de la piscina es esencial para calcular dosificaciones
de químicos en router/readings.py
<<<<<<< HEAD

CAMBIOS (Opción A - Asociar pools a usuarios):
- Todos los endpoints requieren autenticación (Depends(get_current_user))
- Unicidad de pool_id es POR USUARIO (no global)
- Las operaciones se filtran por username del usuario autenticado
=======
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pymongo.database import Database
from datetime import datetime
from typing import List, Optional

from db import get_db
from models import Pool, PoolIn, PoolSettings, TratamientoManualRequest
from routers.auth import get_current_user
<<<<<<< HEAD
from services.calculator import calcular_tratamiento


router = APIRouter(prefix="/api/v1/pools", tags=["pools"])
router_simple = APIRouter(prefix="/pools", tags=["pools"])
=======
from services.calculator import calcular_tratamiento, evaluarAptitud, evaluar_parametros_individuales


router = APIRouter(prefix="/api/v1/pools", tags=["pools"])
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9


@router.post(
    "",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Crear nueva piscina",
    description="Crea un nuevo registro de piscina con volumen especificado y configuración personalizada de rangos"
)
<<<<<<< HEAD
def crear_pool(pool_in: PoolIn, db: Database = Depends(get_db), current_user: dict = Depends(get_current_user)):
=======
def crear_pool(pool_in: PoolIn, db: Database = Depends(get_db)):
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
    """
    Crea una nueva piscina en la base de datos.
    
    **Request Body:**
    - `pool_id`: Identificador único (ej: "POOL_001")
    - `nombre`: Nombre descriptivo
    - `volumen_m3`: Volumen en metros cúbicos (> 0)
    - `activo`: Booleano de estado (default: true)
    - `settings` (OPCIONAL): Configuración personalizada de rangos
      * Si no se envía, adopta estándares de la industria:
        - ph: 7.2 - 7.8
        - cloro: 1.0 - 3.0 ppm
        - temperatura: 24.0 - 30.0 °C
        - conductividad: 1000.0 - 2000.0 µS/cm
    
    **Response (201):**
    ```json
    {
      "ok": true,
      "pool_id": "POOL_001",
      "nombre": "Piscina Principal",
      "volumen_m3": 50.0,
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
      "creado_en": "2025-01-29T14:30:00Z",
      "mensaje": "Pool creado exitosamente"
    }
    ```
    
    **Errores:**
    - 400: pool_id ya existe o volumen inválido
    - 422: Datos inválidos (ej. ph_min > ph_max)
    - 500: Error de BD
    """
    try:
<<<<<<< HEAD
        # ✅ Verificar límite de piscinas por usuario (máximo 3)
        pool_count = db.pools.count_documents({"username": current_user["username"]})
        if pool_count >= 3:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Has alcanzado el límite de 3 piscinas"
            )
        
        # Verificar que no existe ya para este usuario
        existing = db.pools.find_one({"pool_id": pool_in.pool_id, "username": current_user["username"]}, {"_id": 0})
=======
        # Verificar que no existe ya
        existing = db.pools.find_one({"pool_id": pool_in.pool_id})
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Pool '{pool_in.pool_id}' ya existe"
            )
        
        # Convertir modelo Pydantic a diccionario
        # model_dump() maneja correctamente el objeto anidado settings
        doc = pool_in.model_dump()
<<<<<<< HEAD
        doc["username"] = current_user["username"]
=======
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        doc["creado_en"] = datetime.utcnow()
        doc["actualizado_en"] = None
        
        result = db.pools.insert_one(doc)
        
        return {
            "ok": True,
            "pool_id": pool_in.pool_id,
            "nombre": pool_in.nombre,
            "volumen_m3": pool_in.volumen_m3,
            "settings": pool_in.settings.model_dump() if pool_in.settings else PoolSettings().model_dump(),
            "creado_en": doc["creado_en"].isoformat() + "Z",
            "mensaje": "Pool creado exitosamente"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al crear pool: {str(e)}"
        )


@router.get(
    "",
    response_model=dict,
    summary="Listar piscinas",
    description="Retorna lista de todas las piscinas registradas con sus configuraciones"
)
def listar_pools(
    activas_solo: bool = Query(False, description="Mostrar solo pools activos"),
<<<<<<< HEAD
    db: Database = Depends(get_db),
    current_user: dict = Depends(get_current_user)
=======
    db: Database = Depends(get_db)
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
):
    """
    Obtiene lista de todos los pools registrados con sus rangos de configuración.
    
    **Query Parameters:**
    - `activas_solo`: Si es true, solo retorna pools con estado activo=true
    
    **Response (200):**
    ```json
    {
      "total": 2,
      "pools": [
        {
          "pool_id": "POOL_001",
          "nombre": "Piscina Principal",
          "volumen_m3": 50.0,
          "activo": true,
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
          "creado_en": "2025-01-27T10:00:00Z"
        },
        {
          "pool_id": "POOL_002",
          "nombre": "Piscina Infantil",
          "volumen_m3": 20.0,
          "activo": true,
          "settings": {
            "ph_min": 7.0,
            "ph_max": 7.5,
            "cloro_min": 0.5,
            "cloro_max": 2.0,
            "temperatura_min": 26.0,
            "temperatura_max": 32.0,
            "conductividad_min": 800.0,
            "conductividad_max": 1500.0
          },
          "creado_en": "2025-01-28T15:30:00Z"
        }
      ]
    }
    ```
    
    **Errores:**
    - 500: Error de BD
    """
    try:
<<<<<<< HEAD
        # Filtrar por usuario autenticado
        query = {"username": current_user["username"]}
=======
        query = {}
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        if activas_solo:
            query["activo"] = True
        
        pools = list(db.pools.find(query, {"_id": 0}).sort("creado_en", -1))
        
        # Asegurar que todas las piscinas tengan settings (retrocompatibilidad)
        for pool in pools:
            if "settings" not in pool:
                # Si el documento antiguo no tiene settings, usar defaults
                pool["settings"] = PoolSettings().model_dump()
        
        return {
            "total": len(pools),
            "pools": pools
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al listar pools: {str(e)}"
        )


@router.get(
    "/{pool_id}",
    response_model=dict,
    summary="Obtener detalles de piscina",
    description="Retorna la configuración completa de una piscina específica"
)
<<<<<<< HEAD
def obtener_pool(pool_id: str, db: Database = Depends(get_db), current_user: dict = Depends(get_current_user)):
=======
def obtener_pool(pool_id: str, db: Database = Depends(get_db)):
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
    """
    Obtiene los detalles de una piscina específica.
    
    **Path Parameters:**
    - `pool_id`: Identificador de la piscina
    
    **Response (200):**
    ```json
    {
      "pool_id": "POOL_001",
      "nombre": "Piscina Principal",
      "volumen_m3": 50.0,
      "activo": true,
      "creado_en": "2025-01-27T10:00:00Z",
      "actualizado_en": "2025-01-29T08:15:00Z"
    }
    ```
    
    **Errores:**
    - 404: Pool no existe
    - 500: Error de BD
    """
    try:
<<<<<<< HEAD
        # Buscar solo en pools del usuario autenticado
        pool = db.pools.find_one({"pool_id": pool_id, "username": current_user["username"]}, {"_id": 0})
=======
        pool = db.pools.find_one({"pool_id": pool_id}, {"_id": 0})
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        
        if not pool:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )
        
        return pool
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener pool: {str(e)}"
        )


@router.put(
    "/{pool_id}",
    response_model=dict,
    summary="Actualizar piscina",
    description="Actualiza volumen y otros parámetros de una piscina"
)
def actualizar_pool(
    pool_id: str,
    pool_in: PoolIn,
<<<<<<< HEAD
    db: Database = Depends(get_db),
    current_user: dict = Depends(get_current_user)
=======
    db: Database = Depends(get_db)
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
):
    """
    Actualiza la configuración de una piscina existente.
    
    **Path Parameters:**
    - `pool_id`: Identificador de la piscina a actualizar
    
    **Request Body:**
    - `pool_id`: Nuevo pool_id (opcional, si no especifica usa el mismo)
    - `nombre`: Nuevo nombre
    - `volumen_m3`: Nuevo volumen (> 0)
    - `activo`: Nuevo estado
    
    **Response (200):**
    ```json
    {
      "ok": true,
      "pool_id": "POOL_001",
      "nombre": "Piscina Principal (Remodelada)",
      "volumen_m3": 75.0,
      "actualizado_en": "2025-01-29T14:35:00Z",
      "mensaje": "Pool actualizado exitosamente"
    }
    ```
    
    **Errores:**
    - 404: Pool no existe
    - 400: Volumen inválido
    - 500: Error de BD
    """
    try:
<<<<<<< HEAD
        # Verificar que existe y pertenece al usuario
        existing = db.pools.find_one({"pool_id": pool_id, "username": current_user["username"]}, {"_id": 0})
=======
        # Verificar que existe
        existing = db.pools.find_one({"pool_id": pool_id})
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )
        
        # Preparar actualización
        update_data = pool_in.model_dump()
        update_data["actualizado_en"] = datetime.utcnow()
        
<<<<<<< HEAD
        # Actualizar en BD (solo el pool del usuario autenticado)
        result = db.pools.update_one(
            {"pool_id": pool_id, "username": current_user["username"]},
=======
        # Actualizar en BD
        result = db.pools.update_one(
            {"pool_id": pool_id},
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
            {"$set": update_data}
        )
        
        if result.matched_count == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )
        
        # Recuperar documento actualizado
<<<<<<< HEAD
        updated_pool = db.pools.find_one({"pool_id": pool_id, "username": current_user["username"]}, {"_id": 0})
=======
        updated_pool = db.pools.find_one({"pool_id": pool_id}, {"_id": 0})
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        
        return {
            "ok": True,
            "pool_id": updated_pool["pool_id"],
            "nombre": updated_pool["nombre"],
            "volumen_m3": updated_pool["volumen_m3"],
            "activo": updated_pool["activo"],
            "actualizado_en": update_data["actualizado_en"].isoformat() + "Z",
            "mensaje": "Pool actualizado exitosamente"
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al actualizar pool: {str(e)}"
        )


@router.delete(
    "/{pool_id}",
    response_model=dict,
    status_code=status.HTTP_200_OK,
    summary="Eliminar piscina",
    description="Elimina una piscina y sus registros asociados"
)
<<<<<<< HEAD
def eliminar_pool(pool_id: str, db: Database = Depends(get_db), current_user: dict = Depends(get_current_user)):
=======
def eliminar_pool(pool_id: str, db: Database = Depends(get_db)):
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
    """
    Elimina una piscina de la base de datos.
    
    ⚠️ **ADVERTENCIA:** Esta operación es destructiva:
    - Elimina el registro del pool
    - Elimina TODAS las lecturas (lecturas) asociadas a este pool_id
    
    **Path Parameters:**
    - `pool_id`: Identificador del pool a eliminar
    
    **Response (200):**
    ```json
    {
      "ok": true,
      "pool_id": "POOL_001",
      "pool_eliminado": true,
      "lecturas_eliminadas": 47
    }
    ```
    
    **Errores:**
    - 404: Pool no existe
    - 500: Error de BD
    """
    try:
<<<<<<< HEAD
        # Verificar que existe y pertenece al usuario
        pool = db.pools.find_one({"pool_id": pool_id, "username": current_user["username"]}, {"_id": 0})
=======
        # Verificar que existe
        pool = db.pools.find_one({"pool_id": pool_id})
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        if not pool:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )
        
<<<<<<< HEAD
        # Eliminar pool (solo del usuario autenticado)
        db.pools.delete_one({"pool_id": pool_id, "username": current_user["username"]})
=======
        # Eliminar pool
        db.pools.delete_one({"pool_id": pool_id})
>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
        
        # Eliminar todas las lecturas asociadas
        deleted_lecturas = db.lecturas.delete_many({"pool_id": pool_id})
        
        return {
            "ok": True,
            "pool_id": pool_id,
            "pool_eliminado": True,
            "lecturas_eliminadas": deleted_lecturas.deleted_count
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al eliminar pool: {str(e)}"
        )


<<<<<<< HEAD
# ============================================================
# ENDPOINT ALTERNATIVO SIMPLE (sin /api/v1)
# ============================================================

@router_simple.get(
    "",
    response_model=dict,
    summary="Listar piscinas del usuario",
    description="Retorna lista de todas las piscinas del usuario autenticado (endpoint simplificado)"
)
def get_pools_simple(
    db: Database = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    ✅ **Endpoint simplificado**: GET /pools
    
    Retorna todas las piscinas del usuario autenticado.
    
    **Response (200):**
    ```json
    {
      "total": 2,
      "username": "admin",
      "pools": [
        {
          "pool_id": "POOL_001",
          "nombre": "Piscina Principal",
          "volumen_m3": 50.0,
          "activo": true,
          "settings": {...},
          "creado_en": "2025-01-27T10:00:00Z"
        }
      ]
    }
    ```
    """
    try:
        query = {"username": current_user["username"]}
        pools = list(db.pools.find(query, {"_id": 0}).sort("creado_en", -1))
        
        # Retrocompatibilidad: asegurar que todos tengan settings
        for pool in pools:
            if "settings" not in pool:
                pool["settings"] = PoolSettings().model_dump()
        
        return {
            "total": len(pools),
            "username": current_user["username"],
            "pools": pools
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al listar pools: {str(e)}"
        )


@router_simple.get(
    "/{pool_id}",
    response_model=dict,
    summary="Obtener detalles de una piscina",
    description="Retorna los detalles completos de una piscina específica (endpoint simplificado)"
)
def get_pool_simple(
    pool_id: str,
    db: Database = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """
    ✅ **Endpoint simplificado**: GET /pools/{pool_id}
    
    Obtiene los detalles de una piscina específica (solo si pertenece al usuario).
    
    **Path Parameters:**
    - `pool_id`: Identificador de la piscina
    
    **Response (200):**
    ```json
    {
      "pool_id": "POOL_001",
      "nombre": "Piscina Principal",
      "volumen_m3": 50.0,
      "activo": true,
      "settings": {
        "ph_min": 7.2,
        "ph_max": 7.8,
        ...
      },
      "username": "admin",
      "creado_en": "2025-01-27T10:00:00Z",
      "actualizado_en": null
    }
    ```
    
    **Errores:**
    - 404: Pool no existe o no pertenece al usuario
    - 500: Error de BD
    """
    try:
        # Buscar pool específico del usuario (per-user scoping)
        pool = db.pools.find_one(
            {"pool_id": pool_id, "username": current_user["username"]},
            {"_id": 0}
        )
        
        if not pool:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado o no tienes acceso"
            )
        
        # Retrocompatibilidad: asegurar que tenga settings
        if "settings" not in pool:
            pool["settings"] = PoolSettings().model_dump()
        
        return pool
    
=======
@router.get(
    "/{pool_id}/status",
    response_model=dict,
    summary="Obtener estado actual de los parámetros",
    description="Retorna el estado de la piscina evaluado por calculator.py, tomando última lectura de sensor o manual y dando prioridad al sensor."
)
def get_pool_status(pool_id: str, db: Database = Depends(get_db)):
    try:
        # Verificar que el pool existe
        pool = db.pools.find_one({"pool_id": pool_id})
        if not pool:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )

        # Buscar la última lectura de sensor
        lectura_sensor = db.lecturas.find_one({"pool_id": pool_id}, sort=[("timestamp", -1)])
        # Buscar el último mantenimiento manual
        lectura_manual = db.mantenimientos.find_one({"pool_id": pool_id}, sort=[("fecha", -1)])

        # Variables base
        ph, cloro, temperatura = None, None, None
        fuente_ph, fuente_cloro, fuente_temperatura = "ninguna", "ninguna", "ninguna"

        # 1. Asignar manual si existe
        if lectura_manual:
            if lectura_manual.get("ph_medido") is not None:
                ph = lectura_manual.get("ph_medido")
                fuente_ph = "manual"
            if lectura_manual.get("cloro_medido") is not None:
                cloro = lectura_manual.get("cloro_medido")
                fuente_cloro = "manual"
            # Generalmente no hay temp manual en Mantenimiento actual, pero por consistencia:
            if lectura_manual.get("temperatura_medida") is not None:
                temperatura = lectura_manual.get("temperatura_medida")
                fuente_temperatura = "manual"

        # 2. Asignar sensor si existe (Sobrescribe manual - Prioridad Sensor)
        if lectura_sensor:
            if lectura_sensor.get("ph") is not None:
                ph = lectura_sensor.get("ph")
                fuente_ph = "sensor"
            if lectura_sensor.get("cloro") is not None:
                cloro = lectura_sensor.get("cloro")
                fuente_cloro = "sensor"
            if lectura_sensor.get("temperatura") is not None:
                temperatura = lectura_sensor.get("temperatura")
                fuente_temperatura = "sensor"

        # Evaluar aptitud global con calculator.py
        estado_global = evaluarAptitud(ph, cloro, temperatura)

        # Evaluar estados individuales con calculator.py
        estados_individuales = evaluar_parametros_individuales(ph, cloro, temperatura)

        return {
            "ok": True,
            "pool_id": pool_id,
            "estado": estado_global,
            "parametros": {
                "ph": {
                    "valor": ph,
                    "estado": estados_individuales["ph"],
                    "fuente": fuente_ph
                },
                "cloro": {
                    "valor": cloro,
                    "estado": estados_individuales["cloro"],
                    "fuente": fuente_cloro
                },
                "temperatura": {
                    "valor": temperatura,
                    "estado": estados_individuales["temperatura"],
                    "fuente": fuente_temperatura
                }
            }
        }

>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
<<<<<<< HEAD
            detail=f"Error al obtener pool: {str(e)}"
        )
=======
            detail=f"Error al obtener estado de pool: {str(e)}"
        )

>>>>>>> b27f6820b0d96529ef6203c1520e8f04a6bc3fc9
