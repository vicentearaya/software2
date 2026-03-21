import json
import logging
import os
from datetime import datetime, timezone

import pymongo
from pymongo import MongoClient
from pymongo.collection import Collection

logger = logging.getLogger()
logger.setLevel(logging.INFO)

_client: MongoClient | None = None


def _get_collection() -> Collection:
    global _client
    if _client is None:
        uri = os.environ["MONGODB_URI"]
        _client = MongoClient(uri, serverSelectionTimeoutMS=5_000)
        logger.info("MongoDB Atlas: nueva conexión establecida.")
    return _client["cleanpool"]["lecturas"]


def _parse_timestamp(raw) -> str:
    if raw:
        try:
            datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
            return str(raw)
        except ValueError:
            logger.warning("Timestamp '%s' inválido; se genera uno nuevo.", raw)
    ts = datetime.now(timezone.utc).isoformat()
    logger.info("Timestamp generado: %s", ts)
    return ts


def lambda_handler(event: dict, context) -> dict:
    logger.info("Payload: %s", json.dumps(event))

    # ── R-02: validación de pH ────────────────────────────────────────
    try:
        ph = float(event["ph"])
    except (KeyError, TypeError, ValueError) as exc:
        logger.error("Campo 'ph' inválido o ausente: %s", exc)
        return {"statusCode": 200, "rejected": True, "reason": "Campo 'ph' inválido o ausente."}

    if not (0.0 <= ph <= 14.0):
        logger.error(
            "R-02 VIOLADO — pH=%.4f fuera de [0, 14]. id_piscina=%s. Inserción abortada.",
            ph,
            event.get("id_piscina", "DESCONOCIDA"),
        )
        return {
            "statusCode": 200,
            "rejected": True,
            "reason": f"R-02: pH={ph} fuera de [0, 14]. Lectura descartada.",
        }

    # ── Construcción del documento ────────────────────────────────────
    doc = {
        "id_piscina":    event.get("id_piscina"),
        "ph":            ph,
        "temp":          float(event.get("temp", 0.0)),
        "cloro":         float(event.get("cloro", 0.0)),
        "conductividad": float(event.get("conductividad", 0.0)),
        "timestamp":     _parse_timestamp(event.get("timestamp")),
        "ingested_at":   datetime.now(timezone.utc).isoformat(),
    }

    # ── Persistencia ──────────────────────────────────────────────────
    try:
        result = _get_collection().insert_one(doc)
        logger.info("Documento insertado. _id=%s", result.inserted_id)
    except Exception as exc:
        logger.error("Error al insertar en MongoDB Atlas: %s", exc)
        return {"statusCode": 500, "error": str(exc)}

    return {"statusCode": 200, "inserted_id": str(result.inserted_id)}
