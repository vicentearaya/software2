"""
Presencia de dispositivos IoT: ventana online, lecturas recientes e ingesta de temperatura.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Tuple

from pymongo.database import Database

from services.pool_lookup import find_piscina_doc
from services.reading_freshness import ONLINE_WINDOW, is_device_online, is_reading_fresh

logger = logging.getLogger(__name__)

MQTT_TOPIC_PATTERN = "cleanpool/+/temperatura"

# Re-export para tests y routers que importaban desde aquí.
__all__ = [
    "MQTT_TOPIC_PATTERN",
    "ONLINE_WINDOW",
    "is_device_online",
    "is_reading_fresh",
    "ingest_temperature_reading",
    "parse_temperature_payload",
    "process_mqtt_temperature_message",
    "resolve_pool_from_mqtt_topic",
]


def resolve_pool_from_mqtt_topic(
    db: Database, topic_key: str
) -> Optional[Tuple[str, Optional[str]]]:
    """
    Resuelve el segmento del topic MQTT a (pool_id, device_id).
    topic_key: p.ej. 'piscina-1' en cleanpool/piscina-1/temperatura
    """
    key = topic_key.strip()
    if not key:
        return None

    binding = db.device_bindings.find_one(
        {
            "active": True,
            "$or": [{"mqtt_topic_slug": key}, {"device_id": key}],
        },
        {"pool_id": 1, "device_id": 1},
    )
    if binding:
        return binding["pool_id"], binding.get("device_id")

    pool = find_piscina_doc(db, key)
    if pool:
        pool_id = str(pool["_id"])
        bound = db.device_bindings.find_one(
            {"pool_id": pool_id, "active": True},
            {"device_id": 1},
        )
        device_id = bound.get("device_id") if bound else None
        return pool_id, device_id

    binding = db.device_bindings.find_one(
        {"pool_id": key, "active": True},
        {"pool_id": 1, "device_id": 1},
    )
    if binding:
        return binding["pool_id"], binding.get("device_id")

    return None


def parse_temperature_payload(raw: bytes | str) -> Optional[float]:
    text = raw.decode("utf-8") if isinstance(raw, bytes) else raw
    text = text.strip()
    if not text:
        return None
    try:
        data = json.loads(text)
        if isinstance(data, dict) and "temperatura" in data:
            return float(data["temperatura"])
    except (json.JSONDecodeError, TypeError, ValueError):
        pass
    try:
        return float(text)
    except ValueError:
        return None


def ingest_temperature_reading(
    db: Database,
    *,
    pool_id: str,
    temperatura: float,
    device_id: Optional[str] = None,
    timestamp: Optional[datetime] = None,
) -> str:
    ts = timestamp or datetime.now(timezone.utc)
    doc: Dict[str, Any] = {
        "pool_id": pool_id,
        "temperatura": temperatura,
        "timestamp": ts,
        "is_critical": False,
    }
    if device_id:
        doc["device_id"] = device_id.strip()

    result = db.lecturas.insert_one(doc)

    if device_id:
        db.device_bindings.update_one(
            {"device_id": device_id.strip(), "active": True},
            {"$set": {"last_seen_at": ts, "updated_at": ts}},
        )
    else:
        db.device_bindings.update_many(
            {"pool_id": pool_id, "active": True},
            {"$set": {"last_seen_at": ts, "updated_at": ts}},
        )

    return str(result.inserted_id)


def process_mqtt_temperature_message(db: Database, topic: str, payload: bytes) -> bool:
    parts = topic.split("/")
    if len(parts) < 3 or parts[0] != "cleanpool" or parts[-1] != "temperatura":
        logger.warning("Topic MQTT ignorado: %s", topic)
        return False

    topic_key = parts[1]
    resolved = resolve_pool_from_mqtt_topic(db, topic_key)
    if not resolved:
        logger.warning(
            "Sin vínculo ni piscina para topic key '%s' (topic=%s)", topic_key, topic
        )
        return False

    pool_id, device_id = resolved
    temperatura = parse_temperature_payload(payload)
    if temperatura is None:
        logger.warning("Payload MQTT inválido en %s: %r", topic, payload[:120])
        return False

    ingest_temperature_reading(
        db,
        pool_id=pool_id,
        temperatura=temperatura,
        device_id=device_id,
    )
    logger.info(
        "MQTT temperatura pool=%s device=%s valor=%.2f",
        pool_id,
        device_id or "-",
        temperatura,
    )
    return True
