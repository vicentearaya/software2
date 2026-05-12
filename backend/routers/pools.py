"""
pools.py — Endpoints CRUD para Gestión de Piscinas (Pools)

Proporciona operaciones de creación, lectura, actualización y eliminación
de configuraciones de piscinas en MongoDB. Critical para que el módulo
de calculadora de dosis químicas funcione correctamente.

El volumen de la piscina es esencial para calcular dosificaciones
de químicos en router/readings.py
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pymongo.database import Database
from datetime import datetime
from typing import List, Optional

from db import get_db
from models import Pool, PoolIn, PoolSettings, TratamientoManualRequest
from routers.auth import get_current_user
from services.pool_status import build_pool_status_payload


router = APIRouter(prefix="/api/v1/pools", tags=["pools"])


@router.post(
    "",
    response_model=dict,
    status_code=status.HTTP_201_CREATED,
    summary="Crear nueva piscina",
    description="Crea un nuevo registro de piscina con volumen especificado y configuración personalizada de rangos"
)
def crear_pool(pool_in: PoolIn, db: Database = Depends(get_db)):
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
        # Verificar que no existe ya
        existing = db.pools.find_one({"pool_id": pool_in.pool_id})
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Pool '{pool_in.pool_id}' ya existe"
            )
        
        # Convertir modelo Pydantic a diccionario
        # model_dump() maneja correctamente el objeto anidado settings
        doc = pool_in.model_dump()
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
    db: Database = Depends(get_db)
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
        query = {}
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
def obtener_pool(pool_id: str, db: Database = Depends(get_db)):
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
        pool = db.pools.find_one({"pool_id": pool_id}, {"_id": 0})
        
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
    db: Database = Depends(get_db)
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
        # Verificar que existe
        existing = db.pools.find_one({"pool_id": pool_id})
        if not existing:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )
        
        # Preparar actualización
        update_data = pool_in.model_dump()
        update_data["actualizado_en"] = datetime.utcnow()
        
        # Actualizar en BD
        result = db.pools.update_one(
            {"pool_id": pool_id},
            {"$set": update_data}
        )
        
        if result.matched_count == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )
        
        # Recuperar documento actualizado
        updated_pool = db.pools.find_one({"pool_id": pool_id}, {"_id": 0})
        
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
def eliminar_pool(pool_id: str, db: Database = Depends(get_db)):
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
        # Verificar que existe
        pool = db.pools.find_one({"pool_id": pool_id})
        if not pool:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Pool '{pool_id}' no encontrado"
            )
        
        # Eliminar pool
        db.pools.delete_one({"pool_id": pool_id})
        
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


@router.get(
    "/{pool_id}/status",
    response_model=dict,
    summary="Obtener estado actual de los parámetros",
    description="Retorna el estado de la piscina evaluado por calculator.py, tomando última lectura de sensor o manual y dando prioridad al sensor."
)
def get_pool_status(pool_id: str, db: Database = Depends(get_db)):
    """
    Alias histórico bajo /api/v1/pools. La vía recomendada es GET /piscinas/{id}/status (con JWT).

    Evalúa parámetros con prioridad sensor > manual (lecturas + mantenimientos).
    """
    try:
        return build_pool_status_payload(db, pool_id)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al obtener el estado de la piscina: {str(e)}",
        )

