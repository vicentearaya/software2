from fastapi import FastAPI

from config import get_settings
from routers import auth, readings

settings = get_settings()

app = FastAPI(
    title="CleanPool API",
    description=(
        "API de monitoreo IoT para piscinas. "
        "Recibe lecturas de sensores ESP32 vía AWS IoT Core → Lambda → MongoDB Atlas "
        "y las expone al frontend Flutter."
    ),
    version=settings.api_version,
    contact={
        "name": "Equipo CleanPool",
        "url": "https://github.com/software2-main",
    },
    debug=settings.debug,
)

app.include_router(readings.router)
app.include_router(auth.router)


@app.get("/", summary="Health check", tags=["General"])
def root():
    return {"message": "CleanPool API funcionando"}