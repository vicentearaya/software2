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
        
        doc = db.lecturas.find_one(filtro, sort=[("timestamp", -1)])
        
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
