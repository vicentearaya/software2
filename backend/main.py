from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import get_settings
from routers import auth, readings
from routers import ingesta
from routers import piscinas

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

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(readings.router)
app.include_router(auth.router)
app.include_router(ingesta.router, prefix="/api/v1")
app.include_router(piscinas.router)


@app.get("/", summary="Health check", tags=["General"])
def root():
    return {"message": "CleanPool API funcionando"}