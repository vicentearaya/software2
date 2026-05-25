"""
Presencia de dispositivos IoT: ventana online, lecturas recientes e ingesta MQTT.
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

MQTT_TOPIC_PATTERN_TEMP = "cleanpool/+/temperatura"
MQTT_TOPIC_PATTERN_ORP = "cleanpool/+/orp"
MQTT_TOPIC_PATTERNS = (MQTT_TOPIC_PATTERN_TEMP, MQTT_TOPIC_PATTERN_ORP)

# Compatibilidad con imports existentes
MQTT_TOPIC_PATTERN = MQTT_TOPIC_PATTERN_TEMP

# Re-export para tests y routers que importaban desde aquí.
__all__ = [
    "MQTT_TOPIC_PATTERN",
    "MQTT_TOPIC_PATTERN_TEMP",
    "MQTT_TOPIC_PATTERN_ORP",
    "MQTT_TOPIC_PATTERNS",
    "ONLINE_WINDOW",
    "is_device_online",
    "is_reading_fresh",
    "get_latest_fresh_sensor_value",
    "ingest_temperature_reading",
    "ingest_orp_reading",
    "parse_temperature_payload",
    "parse_orp_payload",
    "process_mqtt_temperature_message",
    "process_mqtt_orp_message",
    "process_mqtt_sensor_message",
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


def get_latest_fresh_sensor_value(
    db: Database, pool_id: str, field: str
) -> Optional[float]:
    """Última lectura reciente de un campo (temperatura, orp, etc.) en `lecturas`."""
    doc = db.lecturas.find_one(
        {"pool_id": pool_id, field: {"$exists": True}},
        sort=[("timestamp", -1)],
        projection={field: 1, "timestamp": 1},
    )
    if not doc or not is_reading_fresh(doc.get("timestamp")):
        return None
    value = doc.get(field)
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
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


def parse_orp_payload(raw: bytes | str) -> Optional[float]:
    text = raw.decode("utf-8") if isinstance(raw, bytes) else raw
    text = text.strip()
    if not text:
        return None
    try:
        data = json.loads(text)
        if isinstance(data, dict) and "orp" in data:
            return float(data["orp"])
    except (json.JSONDecodeError, TypeError, ValueError):
        pass
    try:
        return float(text)
    except ValueError:
        return None


def _touch_device_presence(
    db: Database,
    *,
    pool_id: str,
    device_id: Optional[str],
    timestamp: datetime,
) -> None:
    if device_id:
        db.device_bindings.update_one(
            {"device_id": device_id.strip(), "active": True},
            {"$set": {"last_seen_at": timestamp, "updated_at": timestamp}},
        )
    else:
        db.device_bindings.update_many(
            {"pool_id": pool_id, "active": True},
            {"$set": {"last_seen_at": timestamp, "updated_at": timestamp}},
        )


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
    _touch_device_presence(db, pool_id=pool_id, device_id=device_id, timestamp=ts)
    return str(result.inserted_id)


def ingest_orp_reading(
    db: Database,
    *,
    pool_id: str,
    orp: float,
    device_id: Optional[str] = None,
    timestamp: Optional[datetime] = None,
) -> str:
    ts = timestamp or datetime.now(timezone.utc)
    doc: Dict[str, Any] = {
        "pool_id": pool_id,
        "orp": orp,
        "timestamp": ts,
        "is_critical": False,
    }
    if device_id:
        doc["device_id"] = device_id.strip()

    result = db.lecturas.insert_one(doc)
    _touch_device_presence(db, pool_id=pool_id, device_id=device_id, timestamp=ts)
    return str(result.inserted_id)


def _resolve_mqtt_topic(db: Database, topic: str) -> Optional[Tuple[str, Optional[str], str]]:
    parts = topic.split("/")
    if len(parts) < 3 or parts[0] != "cleanpool":
        return None
    suffix = parts[-1]
    if suffix not in ("temperatura", "orp"):
        return None
    topic_key = parts[1]
    resolved = resolve_pool_from_mqtt_topic(db, topic_key)
    if not resolved:
        logger.warning(
            "Sin vínculo ni piscina para topic key '%s' (topic=%s)", topic_key, topic
        )
        return None
    pool_id, device_id = resolved
    return pool_id, device_id, suffix


def process_mqtt_sensor_message(db: Database, topic: str, payload: bytes) -> bool:
    resolved = _resolve_mqtt_topic(db, topic)
    if not resolved:
        if topic.startswith("cleanpool/"):
            logger.warning("Topic MQTT ignorado: %s", topic)
        return False

    pool_id, device_id, suffix = resolved
    if suffix == "temperatura":
        value = parse_temperature_payload(payload)
        if value is None:
            logger.warning("Payload MQTT inválido en %s: %r", topic, payload[:120])
            return False
        ingest_temperature_reading(
            db, pool_id=pool_id, temperatura=value, device_id=device_id
        )
        logger.info(
            "MQTT temperatura pool=%s device=%s valor=%.2f",
            pool_id,
            device_id or "-",
            value,
        )
        return True

    value = parse_orp_payload(payload)
    if value is None:
        logger.warning("Payload MQTT inválido en %s: %r", topic, payload[:120])
        return False
    ingest_orp_reading(db, pool_id=pool_id, orp=value, device_id=device_id)
    logger.info(
        "MQTT ORP pool=%s device=%s valor=%.1f mV",
        pool_id,
        device_id or "-",
        value,
    )
    return True


def process_mqtt_temperature_message(db: Database, topic: str, payload: bytes) -> bool:
    if not topic.endswith("/temperatura"):
        return False
    return process_mqtt_sensor_message(db, topic, payload)


def process_mqtt_orp_message(db: Database, topic: str, payload: bytes) -> bool:
    if not topic.endswith("/orp"):
        return False
    return process_mqtt_sensor_message(db, topic, payload)
