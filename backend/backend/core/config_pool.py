from dataclasses import dataclass
from enum import Enum


class EstadoAgua(str, Enum):
    OPTIMO = "OPTIMO"
    ADVERTENCIA = "ADVERTENCIA"
    CRITICO = "CRITICO"


@dataclass(frozen=True)
class RangoSensor:
    optimo_min: float
    optimo_max: float
    advertencia_min: float
    advertencia_max: float
    mensaje_bajo: str
    mensaje_alto: str
    mensaje_optimo: str
    unidad: str


RANGOS = {
    "ph": RangoSensor(
        optimo_min=7.2, optimo_max=7.8,
        advertencia_min=6.8, advertencia_max=8.2,
        mensaje_bajo="pH bajo: agregar carbonato de sodio.",
        mensaje_alto="pH alto: agregar bisulfato de sodio.",
        mensaje_optimo="pH en rango óptimo.",
        unidad="pH",
    ),
    "cloro": RangoSensor(
        optimo_min=1.0, optimo_max=3.0,
        advertencia_min=0.5, advertencia_max=5.0,
        mensaje_bajo="Cloro bajo: reforzar dosificación.",
        mensaje_alto="Cloro alto: suspender cloración y ventilar.",
        mensaje_optimo="Cloro en nivel seguro.",
        unidad="ppm",
    ),
    "temperatura": RangoSensor(
        optimo_min=24.0, optimo_max=30.0,
        advertencia_min=20.0, advertencia_max=34.0,
        mensaje_bajo="Temperatura baja: verificar calefacción.",
        mensaje_alto="Temperatura alta: riesgo bacteriano.",
        mensaje_optimo="Temperatura dentro del rango confortable.",
        unidad="°C",
    ),
    "conductividad": RangoSensor(
        optimo_min=1000.0, optimo_max=2000.0,
        advertencia_min=500.0, advertencia_max=3000.0,
        mensaje_bajo="Conductividad baja: verificar sales.",
        mensaje_alto="Conductividad alta: exceso de minerales.",
        mensaje_optimo="Conductividad en nivel aceptable.",
        unidad="µS/cm",
    ),
}


def evaluar_sensor(clave: str, valor: float) -> dict:
    if clave not in RANGOS:
        raise ValueError(f"Sensor '{clave}' no reconocido.")
    rango = RANGOS[clave]
    if rango.optimo_min <= valor <= rango.optimo_max:
        estado = EstadoAgua.OPTIMO
        mensaje = rango.mensaje_optimo
    elif rango.advertencia_min <= valor <= rango.advertencia_max:
        estado = EstadoAgua.ADVERTENCIA
        mensaje = rango.mensaje_bajo if valor < rango.optimo_min else rango.mensaje_alto
    else:
        estado = EstadoAgua.CRITICO
        mensaje = rango.mensaje_bajo if valor < rango.advertencia_min else rango.mensaje_alto
    return {"valor": valor, "unidad": rango.unidad, "estado": estado, "mensaje": mensaje}
