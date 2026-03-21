from fastapi import APIRouter, Header, HTTPException, Depends
from datetime import datetime, timezone
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
