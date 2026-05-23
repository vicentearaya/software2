"""Resolución de documentos de piscina en MongoDB (sin dependencias circulares)."""

from __future__ import annotations

from typing import Any, Dict, Optional

from bson import ObjectId
from bson.errors import InvalidId
from pymongo.database import Database


def find_piscina_doc(db: Database, pool_id: str) -> Optional[Dict[str, Any]]:
    """Resuelve por ObjectId o por campo legacy pool_id."""
    try:
        oid = ObjectId(pool_id)
        doc = db.piscinas.find_one({"_id": oid})
        if doc:
            return doc
    except (InvalidId, TypeError):
        pass
    return db.piscinas.find_one({"pool_id": pool_id})
