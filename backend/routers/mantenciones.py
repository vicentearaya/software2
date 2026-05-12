from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from pymongo.database import Database

from db import get_db
from models import MantencionIn, Mantencion
from routers.auth import get_current_user

router = APIRouter(prefix="/mantenciones", tags=["Mantenciones"])


@router.post(
    "/",
    response_model=Mantencion,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar mantenimiento",
    description="Crea un registro de mantenimiento autenticando con JWT. Persiste en la colección `mantenciones`.",
)
def crear_mantencion(
    mantencion_in: MantencionIn,
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    mantencion_data = mantencion_in.model_dump()
    mantencion_data["username"] = current_user["username"]
    mantencion_data["creado_en"] = datetime.now(timezone.utc)

    try:
        db["mantenciones"].insert_one(mantencion_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"No se pudo guardar el mantenimiento: {str(e)}",
        )

    mantencion_data.pop("_id", None)
    return mantencion_data


@router.get(
    "/",
    response_model=List[Mantencion],
    summary="Obtener historial de mantenciones",
    description="Obtiene todas las mantenciones realizadas por el usuario actualmente autenticado.",
)
def obtener_historial(
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    cursor = db["mantenciones"].find(
        {"username": current_user["username"]}, {"_id": 0}
    ).sort("fecha", -1)
    return list(cursor)
