from fastapi import APIRouter, Query, Depends, HTTPException, Header
from pymongo.errors import PyMongoError

from db import get_db
from config import get_settings
from core.config_pool import evaluar_sensor
from services.status_service import evaluar_aptitud_global
from models import StatusGlobalResponse

router = APIRouter(tags=["Readings"])


@router.get(
    "/lecturas/estado",
    summary="Estado actual de los sensores de una piscina",
    description="Obtiene la última lectura, evalúa sensores y determina aptitud global",
    response_model=StatusGlobalResponse
)
def get_lecturas_estado(
    pool_id: str = Query(..., description="ID de la piscina"),
    db = Depends(get_db)
) -> dict:
    """
    Retorna el estado evaluado de todos los sensores + aptitud global de la piscina.

    Estructura de respuesta exitosa (200):
    {
      "piscina_apta": true,
      "sensores_criticos": [],
      "motivo": "Piscina en condiciones APTAS para usar. Todos los sensores en rango óptimo o advertencia.",
      "detalle_sensores": {
        "ph": {"valor": 7.5, "unidad": "pH", "estado": "OPTIMO", "mensaje": "pH en rango óptimo."},
        "cloro": {"valor": 2.0, "unidad": "ppm", "estado": "OPTIMO", "mensaje": "Cloro en nivel seguro."},
        "temperatura": {"valor": 26.0, "unidad": "°C", "estado": "OPTIMO", "mensaje": "Temperatura dentro del rango confortable."},
        "conductividad": {"valor": 1500.0, "unidad": "µS/cm", "estado": "OPTIMO", "mensaje": "Conductividad en nivel aceptable."}
      }
    }

    Respuesta de error (404): Si no existen lecturas previas para el pool_id.
    """
    try:
        # Obtener última lectura para el pool_id ordenada por timestamp descendente
        doc = db.lecturas.find_one({"pool_id": pool_id}, sort=[("timestamp", -1)])

        # Manejo de error 404: Sin lecturas para este pool_id
        if not doc:
            raise HTTPException(
                status_code=404,
                detail="No se encontraron mediciones para esta piscina"
            )

        # Evaluar cada sensor con la función evaluar_sensor
        detalle_sensores = {}
        sensores_a_evaluar = ["ph", "cloro", "temperatura", "conductividad"]

        for sensor in sensores_a_evaluar:
            valor = doc.get(sensor)
            if valor is not None:
                detalle_sensores[sensor] = evaluar_sensor(sensor, valor)
            else:
                # Sensor offline o sin dato
                detalle_sensores[sensor] = None

        # Llamar al servicio para evaluar aptitud global
        status_global = evaluar_aptitud_global(detalle_sensores)

        # Construir respuesta completa
        return {
            "piscina_apta": status_global["piscina_apta"],
            "sensores_criticos": status_global["sensores_criticos"],
            "motivo": status_global["motivo"],
            "detalle_sensores": detalle_sensores
        }
        raise
    except ValueError as e:
        raise HTTPException(status_code=400, detail=f"Error de validación: {str(e)}")
    except PyMongoError as exc:
        raise HTTPException(status_code=500, detail=f"Error en base de datos: {str(exc)}")
