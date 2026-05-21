"""
Inventario de productos químicos por usuario (MongoDB, JWT).
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from bson import ObjectId
from bson.errors import InvalidId
from fastapi import APIRouter, Depends, HTTPException, status
from pymongo import ReturnDocument
from pymongo.database import Database

from db import get_db
from models import InventarioItemCreate, InventarioStockDelta
from routers.auth import get_current_user

router = APIRouter(prefix="/inventario", tags=["Inventario"])

_COLLECTION = "inventario"


def _serialize_doc(doc: dict[str, Any]) -> dict[str, Any]:
    """JSON compatible con InventoryProduct.fromJson en Flutter (camelCase)."""
    creado = doc.get("creado_en")
    if isinstance(creado, datetime):
        creado_str = creado.isoformat()
    else:
        creado_str = datetime.now(timezone.utc).isoformat()
    return {
        "id": str(doc["_id"]),
        "nombre": doc.get("nombre", ""),
        "categoria": doc.get("categoria", ""),
        "cantidad": float(doc.get("cantidad", 0.0)),
        "unidad": doc.get("unidad", ""),
        "notas": doc.get("notas"),
        "creadoEn": creado_str,
    }


def _parse_oid(item_id: str) -> ObjectId:
    try:
        return ObjectId(item_id)
    except InvalidId as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ID de producto inválido",
        ) from exc


@router.get("")
def listar_inventario(
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    username = current_user["username"]
    cursor = db[_COLLECTION].find({"username": username}).sort("creado_en", -1)
    items = [_serialize_doc(d) for d in cursor]
    return {"items": items}


@router.post("", status_code=status.HTTP_201_CREATED)
def crear_item(
    body: InventarioItemCreate,
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    username = current_user["username"]
    now = datetime.now(timezone.utc)
    doc = {
        "username": username,
        "nombre": body.nombre.strip(),
        "categoria": body.categoria,
        "cantidad": float(body.cantidad),
        "unidad": body.unidad,
        "notas": body.notas.strip() if body.notas else None,
        "creado_en": now,
        "actualizado_en": now,
    }
    result = db[_COLLECTION].insert_one(doc)
    created = db[_COLLECTION].find_one({"_id": result.inserted_id})
    assert created is not None
    return _serialize_doc(created)


@router.post("/{item_id}/agregar")
def agregar_stock(
    item_id: str,
    body: InventarioStockDelta,
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    oid = _parse_oid(item_id)
    username = current_user["username"]
    now = datetime.now(timezone.utc)
    res = db[_COLLECTION].find_one_and_update(
        {"_id": oid, "username": username},
        {"$inc": {"cantidad": float(body.cantidad)}, "$set": {"actualizado_en": now}},
        return_document=ReturnDocument.AFTER,
    )
    if res is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Producto no encontrado",
        )
    return _serialize_doc(res)


@router.post("/{item_id}/usar")
def usar_stock(
    item_id: str,
    body: InventarioStockDelta,
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    oid = _parse_oid(item_id)
    username = current_user["username"]
    use_qty = float(body.cantidad)
    now = datetime.now(timezone.utc)

    # Actualización atómica: solo si hay stock suficiente ($expr)
    res = db[_COLLECTION].find_one_and_update(
        {
            "_id": oid,
            "username": username,
            "$expr": {"$gte": ["$cantidad", use_qty]},
        },
        {"$inc": {"cantidad": -use_qty}, "$set": {"actualizado_en": now}},
        return_document=ReturnDocument.AFTER,
    )
    if res is None:
        existing = db[_COLLECTION].find_one({"_id": oid, "username": username})
        if existing is None:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Producto no encontrado",
            )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="No puedes usar más del stock disponible",
        )
    return _serialize_doc(res)


@router.delete("/{item_id}", status_code=status.HTTP_200_OK)
def eliminar_item(
    item_id: str,
    current_user: dict = Depends(get_current_user),
    db: Database = Depends(get_db),
):
    oid = _parse_oid(item_id)
    username = current_user["username"]
    result = db[_COLLECTION].delete_one({"_id": oid, "username": username})
    if result.deleted_count == 0:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Producto no encontrado",
        )
    return {"ok": True, "id": item_id}
