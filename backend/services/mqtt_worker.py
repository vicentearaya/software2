"""
Cliente MQTT en segundo plano: suscribe lecturas de temperatura y las persiste en MongoDB.
"""

from __future__ import annotations

import logging
import threading
import time
from typing import Optional

import paho.mqtt.client as mqtt

from config import Settings
from db import get_db
from services.device_presence import MQTT_TOPIC_PATTERN, process_mqtt_temperature_message

logger = logging.getLogger(__name__)


class MqttIngestWorker:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._thread: Optional[threading.Thread] = None
        self._stop = threading.Event()
        self._client: Optional[mqtt.Client] = None

    def start(self) -> None:
        if not self._settings.mqtt_host:
            logger.info("MQTT_HOST no configurado; worker MQTT no iniciado.")
            return
        if self._thread and self._thread.is_alive():
            return
        self._stop.clear()
        self._thread = threading.Thread(
            target=self._run_loop, name="mqtt-ingest", daemon=True
        )
        self._thread.start()
        logger.info(
            "Worker MQTT iniciado (host=%s, topic=%s)",
            self._settings.mqtt_host,
            MQTT_TOPIC_PATTERN,
        )

    def stop(self) -> None:
        self._stop.set()
        if self._client:
            try:
                self._client.loop_stop()
                self._client.disconnect()
            except Exception:
                pass
            self._client = None
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=5)
        self._thread = None

    def _run_loop(self) -> None:
        while not self._stop.is_set():
            try:
                self._connect_and_loop()
            except Exception:
                logger.exception("Error en bucle MQTT; reintento en 5 s")
            if not self._stop.is_set():
                time.sleep(5)

    def _connect_and_loop(self) -> None:
        host = self._settings.mqtt_host
        port = self._settings.mqtt_port
        client = mqtt.Client(
            mqtt.CallbackAPIVersion.VERSION2,
            client_id="cleanpool-backend-ingest",
        )
        self._client = client

        if self._settings.mqtt_user:
            client.username_pw_set(
                self._settings.mqtt_user,
                self._settings.mqtt_password or "",
            )

        def on_connect(_client, _userdata, _flags, reason_code, _properties=None):
            if reason_code == 0:
                _client.subscribe(MQTT_TOPIC_PATTERN, qos=0)
                logger.info("MQTT conectado y suscrito a %s", MQTT_TOPIC_PATTERN)
            else:
                logger.error("MQTT connect falló: %s", reason_code)

        def on_message(_client, _userdata, msg):
            try:
                db = get_db()
                process_mqtt_temperature_message(db, msg.topic, msg.payload)
            except Exception:
                logger.exception("Error procesando mensaje MQTT %s", msg.topic)

        client.on_connect = on_connect
        client.on_message = on_message
        client.connect(host, port, keepalive=60)
        client.loop_start()

        while not self._stop.is_set():
            time.sleep(1)

        client.loop_stop()
        client.disconnect()


_worker: Optional[MqttIngestWorker] = None


def start_mqtt_worker(settings: Settings) -> MqttIngestWorker:
    global _worker
    _worker = MqttIngestWorker(settings)
    _worker.start()
    return _worker


def stop_mqtt_worker() -> None:
    global _worker
    if _worker:
        _worker.stop()
        _worker = None
