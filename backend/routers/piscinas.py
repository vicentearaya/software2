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
        pools.append(PiscinaOut(
            id=str(doc["_id"]),
            username=doc["username"],
            nombre=doc.get("nombre", ""),
            volumen=doc.get("volumen", 0.0),
            tipo=doc.get("tipo", "exterior"),
            ubicacion=doc.get("ubicacion", ""),
            largo=doc.get("largo", 0.0),
            ancho=doc.get("ancho", 0.0),
            profundidad=doc.get("profundidad", 0.0),
            filtro=doc.get("filtro", True),
        ))
    return pools


@router.put("/piscinas/{pool_id}", response_model=PiscinaOut)
def update_pool(
    pool_id: str,
    pool: PiscinaIn,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Actualiza una piscina existente del usuario autenticado."""
    try:
        oid = ObjectId(pool_id)
    except Exception:
        raise HTTPException(status_code=400, detail="ID inválido")

    existing = db.piscinas.find_one({"_id": oid, "username": current_user["username"]})
    if not existing:
        raise HTTPException(status_code=404, detail="Piscina no encontrada")

    if pool.volumen <= 0:
        raise HTTPException(status_code=422, detail="El volumen debe ser mayor a 0")
    if pool.tipo not in ["interior", "exterior"]:
        raise HTTPException(status_code=422, detail="El tipo debe ser 'interior' o 'exterior'")

    update_data = pool.model_dump()
    db.piscinas.update_one({"_id": oid}, {"$set": update_data})

    return PiscinaOut(
        id=pool_id,
        username=current_user["username"],
        **update_data
    )


@router.delete("/piscinas/{pool_id}", status_code=status.HTTP_200_OK)
def delete_pool(pool_id: str, current_user: dict = Depends(get_current_user), db = Depends(get_db)):
    """Elimina una piscina y sus registros asociados (mantenimientos y lecturas)."""
    try:
        oid = ObjectId(pool_id)
    except Exception:
        raise HTTPException(status_code=400, detail="ID inválido")

    existing = db.piscinas.find_one({"_id": oid, "username": current_user["username"]})
    if not existing:
        raise HTTPException(status_code=404, detail="Piscina no encontrada")

    # Eliminar la piscina
    db.piscinas.delete_one({"_id": oid})
    
    # Eliminar registros asociados
    db.mantenimientos.delete_many({"pool_id": pool_id})
    db.lecturas.delete_many({"pool_id": pool_id})

    return {"ok": True, "message": "Piscina eliminada correctamente"}

from models import TratamientoManualRequest
from services.calculator import calcular_tratamiento

@router.post("/piscinas/{pool_id}/tratamiento", status_code=status.HTTP_201_CREATED)
def calcular_y_guardar_tratamiento(
    pool_id: str,
    request: TratamientoManualRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    Guarda un mantenimiento nuevo con los datos ingresados de pH y Cloro,
    luego de retornar las acciones dictadas por `calcular_tratamiento`.
    """
    try:
        try:
            oid = ObjectId(pool_id)
        except Exception:
            raise HTTPException(status_code=400, detail="ID de piscina inválido")

        # Verificar que el pool existe y obtener su volumen
        pool = db.piscinas.find_one({"_id": oid, "username": current_user["username"]})
        if not pool:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Piscina no encontrada"
            )
        
        volumen_m3 = pool.get("volumen", 0.0)
        if volumen_m3 <= 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="La piscina tiene un volumen de 0 m³, no se puede calcular dosis."
            )
            
        # Calcular dosis con las reglas configuradas
        tratamiento_pasos = calcular_tratamiento(request.ph, request.cloro, volumen_m3)
        
        # Registrar el mantenimiento en la colección "mantenimientos"
        mantenimiento_doc = {
            "pool_id": pool_id,
            "username": current_user["username"],
            "fecha": datetime.now(timezone.utc),
            "ph_medido": request.ph,
            "cloro_medido": request.cloro,
            "acciones": tratamiento_pasos
        }
        
        db.mantenimientos.insert_one(mantenimiento_doc)
        
        return {
            "ok": True,
            "mensaje": "Mantenimiento calculado y guardado exitosamente.",
            "tratamiento": tratamiento_pasos
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al procesar el tratamiento manual: {str(e)}"
        )
