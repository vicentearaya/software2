from fastapi import APIRouter, Depends, HTTPException, status
from db import get_db
from models import MantencionIn, Mantencion
from routers.auth import get_current_user
from typing import List

router = APIRouter(prefix="/mantenciones", tags=["Mantenciones"])
_db = get_db()

@router.post(
    "/",
    response_model=Mantencion,
    status_code=status.HTTP_201_CREATED,
    summary="Registrar mantenimiento",
    description="Crea un registro de mantenimiento autenticando con JWT. Persiste en la colección `mantenciones`."
)
def crear_mantencion(mantencion_in: MantencionIn, current_user: dict = Depends(get_current_user)):
    """
    Registra una nueva mantención vinculada al usuario autenticado.
    Implementa Tareas #1, #2 y #3.
    """
    # Almacenar el username del token en el registro de mantención
    mantencion_data = mantencion_in.model_dump()
    mantencion_data["username"] = current_user["username"]
    
    try:
        _db["mantenciones"].insert_one(mantencion_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error al persistir mantenimiento: {str(e)}"
        )
    
    return mantencion_data


@router.get(
    "/",
    response_model=List[Mantencion],
    summary="Obtener historial de mantenciones",
    description="Obtiene todas las mantenciones realizadas por el usuario actualmente autenticado."
)
def obtener_historial(current_user: dict = Depends(get_current_user)):
    """
    Retorna el historial completo del usuario.
    Implementa Tarea #4.
    """
    # Filtrar por el username del usuario autenticado
    cursor = _db["mantenciones"].find({"username": current_user["username"]}).sort("fecha", -1)
    
    mantenciones = list(cursor)
    return mantenciones
