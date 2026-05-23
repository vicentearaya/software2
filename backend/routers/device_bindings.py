from datetime import datetime, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, Header, HTTPException, status

from config import get_settings
from db import get_db
from models import (
    DeviceBindingIn,
    DeviceBindingResponse,
    DeviceStatusResponse,
    LecturaResponse,
    LecturaTemperaturaDeviceIn,
)
from routers.auth import get_current_user
from services.device_presence import (
    ingest_temperature_reading,
    is_device_online,
    is_reading_fresh,
)

router = APIRouter(tags=["Device Bindings"])


def verify_api_key(x_api_key: str = Header(...), settings=Depends(get_settings)):
    if x_api_key != settings.api_key:
        raise HTTPException(status_code=403, detail="Forbidden")


@router.post(
    "/device/bind",
    response_model=DeviceBindingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Vincular dispositivo a piscina",
)
def bind_device_to_pool(
    payload: DeviceBindingIn,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    """
    Crea/actualiza el vínculo activo de un dispositivo físico hacia una piscina.
    Un dispositivo solo puede tener un vínculo activo a la vez.
    """
    try:
        pool_oid = ObjectId(payload.pool_id)
    except Exception:
        raise HTTPException(status_code=400, detail="pool_id inválido")

    pool = db.piscinas.find_one({"_id": pool_oid, "username": current_user["username"]})
    if not pool:
        raise HTTPException(status_code=404, detail="Piscina no encontrada para el usuario")

    now = datetime.now(timezone.utc)
    device_id = payload.device_id.strip()
    mqtt_slug = (payload.mqtt_topic_slug or device_id).strip()

    db.device_bindings.update_one(
        {"device_id": device_id},
        {
            "$set": {
                "device_id": device_id,
                "pool_id": payload.pool_id,
                "mqtt_topic_slug": mqtt_slug,
                "username": current_user["username"],
                "active": True,
                "updated_at": now,
            },
            "$setOnInsert": {
                "assigned_at": now,
                "last_seen_at": None,
            },
        },
        upsert=True,
    )

    binding_doc = db.device_bindings.find_one(
        {"device_id": device_id},
        {"_id": 0, "device_id": 1, "pool_id": 1, "active": 1, "assigned_at": 1},
    )

    return DeviceBindingResponse(
        ok=True,
        device_id=binding_doc["device_id"],
        pool_id=binding_doc["pool_id"],
        active=bool(binding_doc.get("active", True)),
        assigned_at=binding_doc.get("assigned_at", now),
    )


@router.post(
    "/device/unbind",
    response_model=DeviceBindingResponse,
    summary="Desvincular dispositivo de piscina",
)
def unbind_device_from_pool(
    payload: DeviceBindingIn,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    binding = db.device_bindings.find_one(
        {
            "device_id": payload.device_id.strip(),
            "username": current_user["username"],
            "active": True,
        }
    )
    if not binding:
        raise HTTPException(status_code=404, detail="Dispositivo sin vínculo activo")
    if binding.get("pool_id") != payload.pool_id:
        raise HTTPException(
            status_code=400,
            detail="El dispositivo está vinculado a otra piscina",
        )

    now = datetime.now(timezone.utc)
    db.device_bindings.update_one(
        {"device_id": payload.device_id.strip(), "username": current_user["username"]},
        {"$set": {"active": False, "updated_at": now}},
    )

    return DeviceBindingResponse(
        ok=True,
        device_id=payload.device_id.strip(),
        pool_id=payload.pool_id,
        active=False,
        assigned_at=binding.get("assigned_at", now),
    )


@router.get(
    "/device/{device_id}/binding",
    response_model=DeviceBindingResponse,
    summary="Consultar vínculo activo de dispositivo",
)
def get_device_binding(
    device_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    binding = db.device_bindings.find_one(
        {"device_id": device_id, "username": current_user["username"], "active": True},
        {"_id": 0, "device_id": 1, "pool_id": 1, "active": 1, "assigned_at": 1},
    )
    if not binding:
        raise HTTPException(status_code=404, detail="Dispositivo sin vínculo activo")

    return DeviceBindingResponse(
        ok=True,
        device_id=binding["device_id"],
        pool_id=binding["pool_id"],
        active=bool(binding.get("active", True)),
        assigned_at=binding.get("assigned_at", datetime.now(timezone.utc)),
    )


@router.get(
    "/device/{device_id}/status",
    response_model=DeviceStatusResponse,
    summary="Consultar estado de conexión del dispositivo",
)
def get_device_status(
    device_id: str,
    current_user: dict = Depends(get_current_user),
    db=Depends(get_db),
):
    binding = db.device_bindings.find_one(
        {"device_id": device_id, "username": current_user["username"], "active": True},
        {
            "_id": 0,
            "device_id": 1,
            "pool_id": 1,
            "active": 1,
            "assigned_at": 1,
            "last_seen_at": 1,
            "mqtt_topic_slug": 1,
        },
    )
    if not binding:
        raise HTTPException(status_code=404, detail="Dispositivo sin vínculo activo")

    last_seen = binding.get("last_seen_at")
    now = datetime.now(timezone.utc)
    is_online = is_device_online(last_seen)
    state = "ONLINE" if is_online else "OFFLINE"

    last_temperature = None
    latest = db.lecturas.find_one(
        {"pool_id": binding["pool_id"]},
        sort=[("timestamp", -1)],
        projection={"temperatura": 1, "timestamp": 1},
    )
    if latest and is_reading_fresh(latest.get("timestamp")):
        temp = latest.get("temperatura")
        if temp is not None:
            last_temperature = float(temp)

    return DeviceStatusResponse(
        ok=True,
        device_id=binding["device_id"],
        pool_id=binding["pool_id"],
        active=bool(binding.get("active", True)),
        assigned_at=binding.get("assigned_at", now),
        last_seen_at=last_seen,
        is_online=is_online,
        connection_state=state,
        mqtt_topic_slug=binding.get("mqtt_topic_slug"),
        last_temperature=last_temperature,
    )


@router.post(
    "/lectura/temperatura/device",
    response_model=LecturaResponse,
    summary="Ingesta de temperatura por device_id",
)
def ingest_temperature_from_device(
    payload: LecturaTemperaturaDeviceIn,
    db=Depends(get_db),
    _=Depends(verify_api_key),
):
    """
    Ingesta para ESP8266 usando device_id.
    El backend resuelve automáticamente el pool_id según el vínculo activo.
    """
    binding = db.device_bindings.find_one(
        {"device_id": payload.device_id.strip(), "active": True},
        {"_id": 0, "pool_id": 1},
    )
    if not binding:
        raise HTTPException(status_code=404, detail="No existe vínculo activo para el dispositivo")

    inserted_id = ingest_temperature_reading(
        db,
        pool_id=binding["pool_id"],
        temperatura=payload.temperatura,
        device_id=payload.device_id.strip(),
    )

    return LecturaResponse(ok=True, id=inserted_id, is_critical=False)
