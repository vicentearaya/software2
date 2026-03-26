from fastapi import APIRouter, Header, HTTPException, Depends
from datetime import datetime, timezone
<<<<<<< HEAD
from db import get_db
from config import get_settings
from core.config_pool import evaluar_sensor, EstadoAgua
from models import LecturaIn, LecturaInCompat, LecturaResponse

router = APIRouter(tags=["Ingesta IoT"])

def verify_api_key(x_api_key: str = Header(...), settings=Depends(get_settings)):
    if x_api_key != settings.api_key:
        raise HTTPException(status_code=403, detail="Forbidden")

@router.post("/lectura", summary="POST lectura de sensores (ESP8266)", response_model=LecturaResponse)
def ingest_lectura(lectura: LecturaIn, db=Depends(get_db), _=Depends(verify_api_key)):
    """
    Endpoint para recibir lecturas de sensores del ESP8266.
    Requiere header X-API-KEY válido.
    
    Lógica de Criticidad:
    - Evalúa cada sensor (ph, cloro, temperatura, conductividad)
    - Si CUALQUIERA está en estado CRÍTICO, marca is_critical=True
    - Persiste el booleano en MongoDB para reportabilidad futura
    
    Respuesta:
    {
      "ok": true/false,
      "id": "<id_insertado>",
      "is_critical": true/false
    }
    """
    # Validación básica: pH debe estar en rango físico
    if lectura.ph < 0 or lectura.ph > 14:
        raise HTTPException(
            status_code=400,
            detail="pH fuera de rango físico [0,14]"
        )
    
    # PASO 1: Evaluar cada sensor usando la lógica del "cerebro"
    evaluaciones = {
        "ph": evaluar_sensor("ph", lectura.ph),
        "cloro": evaluar_sensor("cloro", lectura.cloro),
        "temperatura": evaluar_sensor("temperatura", lectura.temperatura),
        "conductividad": evaluar_sensor("conductividad", lectura.conductividad),
    }
    
    # PASO 2: Determinación de criticidad
    # Si CUALQUIER sensor está en CRÍTICO, la lectura es crítica
    es_critico = any(
        eval_result["estado"] == EstadoAgua.CRITICO
        for eval_result in evaluaciones.values()
    )
    
    # PASO 3: Preparar documento para MongoDB
    doc = lectura.model_dump()
    timestamp = datetime.now(timezone.utc)
    doc["timestamp"] = timestamp
    doc["is_critical"] = es_critico  # Persistir la bandera
    
    # PASO 4: Alertar en consola si es crítico (para monitoreo en tiempo real)
    if es_critico:
        sensores_criticos = [
            sensor for sensor, result in evaluaciones.items()
            if result["estado"] == EstadoAgua.CRITICO
        ]
        print(
            f"⚠️  ALERTA CRÍTICA — Pool '{lectura.pool_id}' en estado NO APTO\n"
            f"   Timestamp: {timestamp.isoformat()}\n"
            f"   Sensores críticos: {', '.join(sensores_criticos)}\n"
            f"   Detalles:\n"
            + "\n".join(
                f"   - {sensor}: {evaluaciones[sensor]['valor']} {evaluaciones[sensor]['unidad']} "
                f"({evaluaciones[sensor]['mensaje']})"
                for sensor in sensores_criticos
            )
        )
    
    # PASO 5: Insertar en MongoDB
    result = db.lecturas.insert_one(doc)
    
    return LecturaResponse(
        ok=True,
        id=str(result.inserted_id),
        is_critical=es_critico
    )



@router.post("/sensor/data", summary="POST lectura de sensores (compatibilidad)")
def ingest_data(lectura: LecturaInCompat, db=Depends(get_db), _=Depends(verify_api_key)):
    """
    Endpoint legacy para recibir lecturas en formato anterior.
    Mantiene compatibilidad con implementaciones previas.
    
    También aplica la lógica de criticidad detectando sensores en estado CRÍTICO.
    """
    if lectura.ph < 0 or lectura.ph > 14:
        return {"statusCode": 400, "rejected": True, "reason": "R-02: pH fuera de rango físico [0,14]"}
    
    # Mapear campos legacy a nombres estándar
    doc = {
        "pool_id": lectura.id_piscina,
        "ph": lectura.ph,
        "cloro": lectura.cloro,
        "temperatura": lectura.temp,
        "conductividad": lectura.conductividad,
    }
    
    # Evaluar criticidad usando los mismos rangos
    evaluaciones = {
        "ph": evaluar_sensor("ph", lectura.ph),
        "cloro": evaluar_sensor("cloro", lectura.cloro),
        "temperatura": evaluar_sensor("temperatura", lectura.temp),
        "conductividad": evaluar_sensor("conductividad", lectura.conductividad),
    }
    
    es_critico = any(
        eval_result["estado"] == EstadoAgua.CRITICO
        for eval_result in evaluaciones.values()
    )
    
    timestamp = datetime.now(timezone.utc)
    doc["timestamp"] = timestamp
    doc["is_critical"] = es_critico
    
    if es_critico:
        sensores_criticos = [
            sensor for sensor, result in evaluaciones.items()
            if result["estado"] == EstadoAgua.CRITICO
        ]
        print(
            f"⚠️  ALERTA CRÍTICA (legacy) — Pool '{lectura.id_piscina}' en estado NO APTO\n"
            f"   Timestamp: {timestamp.isoformat()}\n"
            f"   Sensores críticos: {', '.join(sensores_criticos)}"
        )
    
    result = db.lecturas.insert_one(doc)
    
    return {
        "statusCode": 200,
        "inserted": True,
        "timestamp": str(timestamp),
        "is_critical": es_critico,
        "id": str(result.inserted_id)
    }


=======
from pydantic import BaseModel
from db import get_db
from config import get_settings

router = APIRouter(tags=["Ingesta IoT"])

class LecturaIn(BaseModel):
    id_piscina: str
    ph: float
    temp: float
    cloro: float
    conductividad: float

def verify_api_key(x_api_key: str = Header(...), settings=Depends(get_settings)):
    if x_api_key != settings.api_key:
        raise HTTPException(status_code=401, detail="Invalid API Key")

@router.post("/sensor/data")
def ingest_data(lectura: LecturaIn, db=Depends(get_db), _=Depends(verify_api_key)):
    if lectura.ph < 0 or lectura.ph > 14:
        return {"statusCode": 200, "rejected": True, "reason": "R-02: pH fuera de rango físico [0,14]"}
    
    doc = lectura.model_dump()
    timestamp = datetime.now(timezone.utc)
    doc["timestamp"] = timestamp
    
    db.lecturas.insert_one(doc)
    
    return {"statusCode": 200, "inserted": True, "timestamp": str(timestamp)}
>>>>>>> 8d6fa66eeb4773c14bbae33fd940f32bb7db3a6d
