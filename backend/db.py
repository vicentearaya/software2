from pymongo import MongoClient
from pymongo.database import Database

from config import get_settings

import certifi

settings = get_settings()

_client = MongoClient(
    str(settings.mongodb_uri),
    serverSelectionTimeoutMS=5_000,
    tls=True,
    tlsCAFile=certifi.where()
)


def get_db() -> Database:
    """Devuelve la instancia de la base de datos MongoDB (singleton por proceso)."""
    return _client[settings.database_name]


def ensure_indexes(db: Database) -> None:
    """
    Crea índices para optimizar queries y mantener integridad de datos.
    Índices: (pool_id, username) para unicidad per-user + queries rápidas
    
    Se llama una sola vez en startup de la aplicación.
    MongoDB ignora llamadas repetidas si el índice ya existe.
    
    Args:
        db: Instancia de base de datos MongoDB
    """
    try:
        # Índice compound para filtros y uniqueness per-user
        db.pools.create_index(
            [("pool_id", 1), ("username", 1)],
            unique=False,
            name="idx_pool_id_username"
        )
        
        # Índice para queries por usuario solamente
        db.pools.create_index(
            [("username", 1)],
            name="idx_username"
        )
        
        # Índice para ordenar por fecha de creación (usado en GET pools)
        db.pools.create_index(
            [("creado_en", -1)],
            name="idx_creado_en_desc"
        )
        
        print("✓ Índices de MongoDB creados/verificados")
    except Exception as e:
        print(f"⚠ Error creando índices (no bloquea startup): {str(e)}")
