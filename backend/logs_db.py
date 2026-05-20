"""Cliente MongoDB dedicado a logs de aplicación (separado de la BD operativa)."""

from __future__ import annotations

import certifi
from pymongo import MongoClient
from pymongo.collection import Collection

from config import get_settings

settings = get_settings()

_logs_client: MongoClient | None = None


def _build_client_kwargs(uri: str) -> dict:
    kwargs: dict = {"serverSelectionTimeoutMS": 5_000}
    use_tls = uri.startswith("mongodb+srv://") or "tls=true" in uri.lower()
    if use_tls:
        kwargs["tls"] = True
        kwargs["tlsCAFile"] = certifi.where()
    return kwargs


def get_logs_collection() -> Collection | None:
    """
    Colección donde se insertan documentos de log estructurados.
    Si MONGODB_LOGS_URI no está configurado, devuelve None (no se persiste en BD).
    """
    uri = settings.mongodb_logs_uri
    if not uri:
        return None
    global _logs_client
    if _logs_client is None:
        _logs_client = MongoClient(str(uri), **_build_client_kwargs(str(uri)))
    db = _logs_client[settings.mongodb_logs_database]
    return db[settings.mongodb_logs_collection]
