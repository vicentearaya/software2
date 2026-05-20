import certifi
from pymongo import MongoClient
from pymongo.database import Database

from config import get_settings

settings = get_settings()

_uri = str(settings.mongodb_uri)
# Atlas (mongodb+srv) usa TLS; Mongo en Docker / local suele ser mongodb:// sin TLS.
_use_tls = _uri.startswith("mongodb+srv://") or "tls=true" in _uri.lower()

_client_kwargs: dict = {"serverSelectionTimeoutMS": 5_000}
if _use_tls:
    _client_kwargs["tls"] = True
    _client_kwargs["tlsCAFile"] = certifi.where()

_client = MongoClient(_uri, **_client_kwargs)


def get_db() -> Database:
    """Devuelve la instancia de la base de datos MongoDB (singleton por proceso)."""
    return _client[settings.database_name]
