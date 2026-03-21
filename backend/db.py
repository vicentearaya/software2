from pymongo import MongoClient
from pymongo.database import Database

from config import get_settings

settings = get_settings()

_client = MongoClient(str(settings.mongodb_uri), serverSelectionTimeoutMS=5_000)


def get_db() -> Database:
    """Devuelve la instancia de la base de datos MongoDB (singleton por proceso)."""
    return _client[settings.database_name]
