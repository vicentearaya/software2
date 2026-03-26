<<<<<<< HEAD
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



=======
from fastapi import APIRouter, Query, Depends
from pymongo.errors import PyMongoError

from db import get_db

router = APIRouter(tags=["Readings"])

def _calcular_estado(parametro: str, valor: float) -> str:
    if valor is None:
        return "desconocido"
        
    if parametro == "ph":
        if 7.2 <= valor <= 7.8:
            return "optimo"
        elif (6.5 <= valor < 7.2) or (7.8 < valor <= 8.5):
            return "alerta"
        else:
            return "critico"
    
    elif parametro == "cloro":
        if 1.0 <= valor <= 3.0:
            return "optimo"
        elif (0.5 <= valor < 1.0) or (3.0 < valor <= 5.0):
            return "alerta"
        else:
            return "critico"
    
    elif parametro == "temp":
        if 24.0 <= valor <= 28.0:
            return "optimo"
        elif (20.0 <= valor < 24.0) or (28.0 < valor <= 32.0):
            return "alerta"
        else:
            return "critico"
    
    elif parametro == "conductividad":
        if 1000.0 <= valor <= 2000.0:
            return "optimo"
        elif (500.0 <= valor < 1000.0) or (2000.0 < valor <= 3000.0):
            return "alerta"
        else:
            return "critico"
    
    return "desconocido"


@router.get(
    "/readings",
    summary="Última lectura del sensor"
)
def get_readings(id_piscina: str = Query(None, description="ID de la piscina (opcional)"), db = Depends(get_db)):
    try:
        filtro = {}
        if id_piscina:
            filtro["id_piscina"] = id_piscina
        
        doc = db["lecturas"].find_one(filtro, sort=[("timestamp", -1)])
        
        if not doc:
            return {"message": "Sin lecturas disponibles aún."}
            
        return {
            "id_piscina": doc.get("id_piscina"),
            "timestamp": str(doc.get("timestamp")),
            "parametros": {
                "ph": {"valor": doc.get("ph"), "estado": _calcular_estado("ph", doc.get("ph"))},
                "temp": {"valor": doc.get("temp"), "estado": _calcular_estado("temp", doc.get("temp"))},
                "cloro": {"valor": doc.get("cloro"), "estado": _calcular_estado("cloro", doc.get("cloro"))},
                "conductividad": {"valor": doc.get("conductividad"), "estado": _calcular_estado("conductividad", doc.get("conductividad"))}
            }
        }
    except PyMongoError as exc:
        return {"error": str(exc)}
>>>>>>> 8d6fa66eeb4773c14bbae33fd940f32bb7db3a6d
