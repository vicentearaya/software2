from typing import List
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from bson import ObjectId

from db import get_db
from routers.auth import get_current_user

router = APIRouter(tags=["Piscinas"])

class PiscinaIn(BaseModel):
    nombre: str
    volumen: float
    tipo: str
    ubicacion: str
    largo: float = 0.0
    ancho: float = 0.0
    profundidad: float = 0.0
    filtro: bool = True

class PiscinaOut(PiscinaIn):
    id: str
    username: str

@router.post("/piscinas", response_model=PiscinaOut, status_code=status.HTTP_201_CREATED)
def create_pool(pool: PiscinaIn, current_user: dict = Depends(get_current_user), db = Depends(get_db)):
    # Validaciones manuales según requerimiento
    if pool.volumen <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="El volumen debe ser mayor a 0"
        )
    if pool.tipo not in ["interior", "exterior"]:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="El tipo de piscina debe ser 'interior' o 'exterior'"
        )

    pool_dict = pool.model_dump()
    pool_dict["username"] = current_user["username"]
    pool_dict["created_at"] = datetime.now(timezone.utc)
    
    result = db.piscinas.insert_one(pool_dict)
    
    return PiscinaOut(
        id=str(result.inserted_id),
        username=current_user["username"],
        **pool.model_dump()
    )

@router.get("/piscinas", response_model=List[PiscinaOut])
def get_pools(current_user: dict = Depends(get_current_user), db = Depends(get_db)):
    cursor = db.piscinas.find({"username": current_user["username"]})
    pools = []
    for doc in cursor:
        # Mapeo de documento a PiscinaOut
        pools.append(PiscinaOut(
            id=str(doc["_id"]),
            username=doc["username"],
            nombre=doc["nombre"],
            volumen=doc["volumen"],
            tipo=doc["tipo"],
            ubicacion=doc["ubicacion"]
        ))
    return pools
