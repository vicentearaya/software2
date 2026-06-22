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
        "unidad_etiqueta": "g",
        "descripcion": "Aumenta el pH cuando el agua está demasiado ácida.",
        "seguridad": "Usar guantes y agregar en pequeñas dosis con la bomba funcionando.",
        "orden": 1,
        "activo": True,
    },
    {
        "slug": "reductor_ph",
        "nombre": "Reductor de pH (ácido muriático o bisulfato)",
        "categoria": "Regulador pH",
        "unidad": "ml",
        "unidad_etiqueta": "ml",
        "descripcion": "Disminuye el pH cuando el agua está demasiado alcalina.",
        "seguridad": "Manipular con guantes y evitar inhalar vapores o salpicaduras.",
        "orden": 2,
        "activo": False,
    },
    {
        "slug": "reductor_ph_granulado",
        "nombre": "Reductor de pH granulado (bisulfato)",
        "categoria": "Regulador pH",
        "unidad": "g",
        "unidad_etiqueta": "g",
        "descripcion": "Baja el pH usando un producto sólido o granulado.",
        "seguridad": "Usar guantes, evitar inhalar polvo y disolver según indicación del envase.",
        "orden": 2,
        "activo": True,
    },
    {
        "slug": "reductor_ph_liquido",
        "nombre": "Reductor de pH líquido (ácido muriático)",
        "categoria": "Regulador pH",
        "unidad": "ml",
        "unidad_etiqueta": "ml",
        "descripcion": "Baja el pH usando un producto líquido de acción rápida.",
        "seguridad": "Manipular con guantes y protección ocular; evitar vapores y salpicaduras.",
        "orden": 3,
        "activo": True,
    },
    {
        "slug": "cloro_granulado",
        "nombre": "Cloro granulado",
        "categoria": "Desinfectante",
        "unidad": "g",
        "unidad_etiqueta": "g",
        "descripcion": "Desinfecta el agua y ayuda a controlar bacterias y microorganismos.",
        "seguridad": "No mezclar con otros químicos y mantener fuera del alcance de niños.",
        "orden": 4,
        "activo": True,
    },
    {
        "slug": "algicida",
        "nombre": "Algicida",
        "categoria": "Algicida",
        "unidad": "ml",
        "unidad_etiqueta": "ml",
        "descripcion": "Ayuda a prevenir y controlar la aparición de algas.",
        "seguridad": "Aplicar según indicación del envase y evitar contacto directo con ojos.",
        "orden": 5,
        "activo": True,
    },
    {
        "slug": "clarificador",
        "nombre": "Clarificador",
        "categoria": "Floculante",
        "unidad": "ml",
        "unidad_etiqueta": "ml",
        "descripcion": "Agrupa partículas pequeñas para mejorar la claridad del agua.",
        "seguridad": "No sobredosificar y mantener la filtración activa tras aplicarlo.",
        "orden": 6,
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
        "descripcion": doc.get("descripcion", ""),
        "seguridad": doc.get("seguridad", ""),
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
