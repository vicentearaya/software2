from fastapi import APIRouter
from pymongo.errors import PyMongoError

from db import get_db

router = APIRouter(tags=["Readings"])

_db = get_db()


@router.get(
    "/readings",
    summary="Última lectura del sensor",
    description="Retorna el documento más reciente de la colección `lecturas`, ordenado por `timestamp` descendente.",
)
def get_readings():
    try:
        doc = _db["lecturas"].find_one(
            filter={},
            sort=[("timestamp", -1)],
            projection={"_id": 0},
        )
    except PyMongoError as exc:
        return {"error": str(exc)}

    if doc is None:
        return {"message": "Sin lecturas disponibles aún."}
    return doc
