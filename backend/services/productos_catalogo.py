"""
Catálogo de productos químicos usados por la calculadora de tratamiento.
Se persiste en MongoDB (`productos_catalogo`) y se expone al inventario.
"""

from __future__ import annotations

from typing import Any

from pymongo.database import Database

_COLLECTION = "productos_catalogo"

# Mismos nombres y unidades que `calcular_tratamiento` en calculator.py (sin "Ninguno").
CATALOG_PRODUCTS: list[dict[str, Any]] = [
    {
        "slug": "elevador_ph",
        "nombre": "Elevador de pH (carbonato de sodio)",
        "categoria": "Regulador pH",
        "unidad": "g",
        "unidad_etiqueta": "gr",
        "orden": 1,
        "activo": True,
    },
    {
        "slug": "reductor_ph",
        "nombre": "Reductor de pH (ácido muriático o bisulfato)",
        "categoria": "Regulador pH",
        "unidad": "ml",
        "unidad_etiqueta": "ml",
        "orden": 2,
        "activo": True,
    },
    {
        "slug": "cloro_granulado",
        "nombre": "Cloro granulado",
        "categoria": "Desinfectante",
        "unidad": "g",
        "unidad_etiqueta": "gr",
        "orden": 3,
        "activo": True,
    },
]


def _serialize(doc: dict[str, Any]) -> dict[str, Any]:
    return {
        "slug": doc.get("slug", ""),
        "nombre": doc.get("nombre", ""),
        "categoria": doc.get("categoria", ""),
        "unidad": doc.get("unidad", ""),
        "unidadEtiqueta": doc.get("unidad_etiqueta", doc.get("unidad", "")),
        "orden": int(doc.get("orden", 0)),
    }


def ensure_catalog(db: Database) -> None:
    """Inserta o actualiza el catálogo canónico (idempotente por slug)."""
    col = db[_COLLECTION]
    for product in CATALOG_PRODUCTS:
        col.update_one(
            {"slug": product["slug"]},
            {"$set": product},
            upsert=True,
        )


def list_catalog(db: Database) -> list[dict[str, Any]]:
    ensure_catalog(db)
    cursor = db[_COLLECTION].find({"activo": True}).sort("orden", 1)
    return [_serialize(d) for d in cursor]
