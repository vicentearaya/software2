"""
Estado del agua (pH, cloro, temperatura) para una piscina de la colección `piscinas`.

Unifica la lógica usada por GET /piscinas/{id}/status y el alias GET /api/v1/pools/{id}/status.
"""

from __future__ import annotations

from typing import Any, Dict, Optional

from bson import ObjectId
from bson.errors import InvalidId
from fastapi import HTTPException, status
from pymongo.database import Database

from services.calculator import evaluarAptitud, evaluar_parametros_individuales


def _find_piscina_doc(db: Database, pool_id: str) -> Optional[Dict[str, Any]]:
    """Resuelve por ObjectId o por campo legacy pool_id."""
    try:
        oid = ObjectId(pool_id)
        doc = db.piscinas.find_one({"_id": oid})
        if doc:
            return doc
    except (InvalidId, TypeError):
        pass
    return db.piscinas.find_one({"pool_id": pool_id})


def build_pool_status_payload(db: Database, pool_id: str) -> Dict[str, Any]:
    """
    Construye el cuerpo JSON de estado (claves ok, pool_id, estado, parametros).
    No comprueba propiedad del usuario; eso lo hace el router de /piscinas.
    """
    pool = _find_piscina_doc(db, pool_id)
    if not pool:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No se encontró la piscina con el identificador indicado.",
        )

    lectura_sensor = db.lecturas.find_one(
        {"pool_id": pool_id}, sort=[("timestamp", -1)]
    )
    lectura_manual = db.mantenimientos.find_one(
        {"pool_id": pool_id}, sort=[("fecha", -1)]
    )

    ph, cloro, temperatura = None, None, None
    fuente_ph, fuente_cloro, fuente_temperatura = "ninguna", "ninguna", "ninguna"

    if lectura_manual:
        if lectura_manual.get("ph_medido") is not None:
            ph = lectura_manual.get("ph_medido")
            fuente_ph = "manual"
        if lectura_manual.get("cloro_medido") is not None:
            cloro = lectura_manual.get("cloro_medido")
            fuente_cloro = "manual"
        if lectura_manual.get("temperatura_medida") is not None:
            temperatura = lectura_manual.get("temperatura_medida")
            fuente_temperatura = "manual"

    if lectura_sensor:
        if lectura_sensor.get("ph") is not None:
            ph = lectura_sensor.get("ph")
            fuente_ph = "sensor"
        if lectura_sensor.get("cloro") is not None:
            cloro = lectura_sensor.get("cloro")
            fuente_cloro = "sensor"
        if lectura_sensor.get("temperatura") is not None:
            temperatura = lectura_sensor.get("temperatura")
            fuente_temperatura = "sensor"

    estado_global = evaluarAptitud(ph, cloro, temperatura)
    estados_individuales = evaluar_parametros_individuales(ph, cloro, temperatura)

    return {
        "ok": True,
        "pool_id": pool_id,
        "estado": estado_global,
        "parametros": {
            "ph": {
                "valor": ph,
                "estado": estados_individuales["ph"],
                "fuente": fuente_ph,
            },
            "cloro": {
                "valor": cloro,
                "estado": estados_individuales["cloro"],
                "fuente": fuente_cloro,
            },
            "temperatura": {
                "valor": temperatura,
                "estado": estados_individuales["temperatura"],
                "fuente": fuente_temperatura,
            },
        },
    }


def build_pool_status_for_owner(
    db: Database, pool_id: str, username: str
) -> Dict[str, Any]:
    """Igual que build_pool_status_payload pero exige que la piscina pertenezca al usuario."""
    pool = _find_piscina_doc(db, pool_id)
    if not pool or pool.get("username") != username:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Piscina no encontrada o no pertenece a tu cuenta.",
        )
    return build_pool_status_payload(db, pool_id)
