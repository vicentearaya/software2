"""
Catálogo de productos químicos (MongoDB) para alta masiva en inventario.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from pymongo.database import Database

from db import get_db
from routers.auth import get_current_user
from services.productos_catalogo import list_catalog

router = APIRouter(prefix="/productos", tags=["Productos"])


@router.get("/catalogo")
def obtener_catalogo(
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    """Lista productos del catálogo (mismos que usa la calculadora de tratamiento)."""
    _ = current_user
    items = list_catalog(db)
    return {"items": items}
