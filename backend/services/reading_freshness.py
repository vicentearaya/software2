"""Ventana de validez para lecturas de sensor (online / stale)."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Optional

# Sin lectura MQTT en este intervalo → OFFLINE (ESP publica cada 10 s).
ONLINE_WINDOW = timedelta(minutes=2)


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def is_reading_fresh(
    timestamp: Optional[datetime], *, window: timedelta = ONLINE_WINDOW
) -> bool:
    if timestamp is None:
        return False
    now = datetime.now(timezone.utc)
    return (now - _ensure_utc(timestamp)) <= window


def is_device_online(last_seen_at: Optional[datetime]) -> bool:
    return is_reading_fresh(last_seen_at)
