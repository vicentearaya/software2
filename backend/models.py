from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional, Any


class UserLogin(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class PoolSettings(BaseModel):
    """
    Configuración personalizada de rangos aceptables para una piscina.
    Implementa Tarea #66 - US-10: "Como técnico quiero configurar los rangos 
    aceptables de cada parámetro según las condiciones específicas de la piscina."
    
    Usa valores de la industria como defaults si el usuarios no especifica.
    """
    ph_min: float = Field(
        default=7.2,
        ge=0.0,
        le=14.0,
        description="pH mínimo aceptable (default: 7.2 - estándar industria)"
    )
    ph_max: float = Field(
        default=7.8,
        ge=0.0,
        le=14.0,
        description="pH máximo aceptable (default: 7.8 - estándar industria)"
    )
    cloro_min: float = Field(
        default=1.0,
        ge=0.0,
        description="Cloro mínimo aceptable en ppm (default: 1.0 - estándar industria)"
    )
    cloro_max: float = Field(
        default=3.0,
        ge=0.0,
        description="Cloro máximo aceptable en ppm (default: 3.0 - estándar industria)"
    )
    temperatura_min: float = Field(
        default=24.0,
        description="Temperatura mínima aceptable en °C (default: 24.0 - estándar industria)"
    )
    temperatura_max: float = Field(
        default=30.0,
        description="Temperatura máxima aceptable en °C (default: 30.0 - estándar industria)"
    )
    conductividad_min: float = Field(
        default=1000.0,
        ge=0.0,
        description="Conductividad mínima aceptable en µS/cm (default: 1000.0 - estándar industria)"
    )
    conductividad_max: float = Field(
        default=2000.0,
        ge=0.0,
        description="Conductividad máxima aceptable en µS/cm (default: 2000.0 - estándar industria)"
    )


class PoolIn(BaseModel):
    """Modelo para crear/actualizar una piscina"""
    pool_id: str = Field(..., description="Identificador único de la piscina")
    nombre: str = Field(..., description="Nombre de la piscina")
    volumen_m3: float = Field(..., gt=0, description="Volumen en metros cúbicos")
    activo: bool = Field(default=True, description="¿Está activa la piscina?")
    settings: Optional[PoolSettings] = Field(
        default_factory=PoolSettings,
        description="Configuración personalizada de rangos. Si no se especifica, usa defaults de la industria."
    )


class Pool(PoolIn):
    """Modelo para respuesta de piscina (con metadata)"""
    creado_en: datetime = Field(default_factory=datetime.utcnow)
    actualizado_en: Optional[datetime] = None
    
    model_config = ConfigDict(from_attributes=True)


class LecturaIn(BaseModel):
    """Modelo para ingestar lectura de sensores desde ESP8266"""
    pool_id: str
    ph: float = Field(..., ge=0, le=14, description="pH (0-14)")
    cloro: float = Field(..., ge=0, description="Cloro en ppm")
    temperatura: float = Field(..., ge=-40, le=60, description="Temperatura en °C")
    conductividad: float = Field(..., ge=0, description="Conductividad en µS/cm")


class LecturaTemperaturaIn(BaseModel):
    """Modelo para ingestar solo temperatura desde ESP8266"""
    pool_id: str
    temperatura: float = Field(..., ge=-40, le=60, description="Temperatura en °C")


class LecturaInCompat(BaseModel):
    """Modelo legacy para compatibilidad (sensor/data) - MANTIENE NOMBRES ORIGINALES"""
    id_piscina: str
    ph: float
    cloro: float
    temp: float
    conductividad: float


class LecturaResponse(BaseModel):
    """Modelo de respuesta para lecturas con criticidad"""
    ok: bool
    id: str
    is_critical: bool = Field(description="True si algún sensor está en estado CRÍTICO")


class SensorEvaluacion(BaseModel):
    """Modelo para la evaluación de un sensor individual"""
    valor: float = Field(description="Valor numérico medido del sensor")
    unidad: str = Field(description="Unidad de medida (pH, ppm, °C, µS/cm)")
    estado: str = Field(description="Estado del sensor: OPTIMO, ADVERTENCIA, CRITICO")
    mensaje: str = Field(description="Mensaje descriptivo del estado")


class StatusGlobalResponse(BaseModel):
    """
    Modelo de respuesta para el endpoint GET /lecturas/estado.
    
    Incluye la evaluación individual de cada sensor + evaluación global de aptitud.
    Implementa Tarea #61 - US-8: "Como propietario quiero visualizar un
    indicador APTA / NO APTA en la aplicación de forma clara y visible"
    """
    piscina_apta: bool = Field(
        True,
        description="True si TODOS los sensores están en OPTIMO/ADVERTENCIA. "
                    "False si AL MENOS UNO está en CRITICO"
    )
    sensores_criticos: list[str] = Field(
        default_factory=list,
        description="Lista de nombres de sensores en estado CRITICO. Vacía si piscina_apta=True"
    )
    motivo: str = Field(
        description="Texto descriptivo de por qué la piscina es APTA o NO APTA. "
                    "Incluye recomendaciones de acción si hay sensores críticos"
    )
    detalle_sensores: dict[str, Optional[SensorEvaluacion]] = Field(
        description="Evaluación detallada de cada uno de los 4 sensores (pH, cloro, temperatura, conductividad)"
    )
    tratamiento: list[dict] = Field(
        default_factory=list,
        description="Lista ordenada de pasos y productos recomendados para tratar el agua, si aplica."
    )
    model_config = ConfigDict(from_attributes=True)


class UserRegister(BaseModel):
    name: str
    username: str
    email: str
    password: str

class TratamientoManualRequest(BaseModel):
    ph: float = Field(..., ge=0.0, le=14.0, description="Valor actual de pH medido manualmente (0-14)")
    cloro: float = Field(..., ge=0.0, le=10.0, description="Valor actual de Cloro medido manualmente en ppm (0-10)")


class MantencionIn(BaseModel):
    """
    Modelo para registrar un mantenimiento de piscina.
    Tarea #2: Definir y validar schema con Pydantic.
    """
    id_piscina: str = Field(..., description="Identificador de la piscina")
    productos: list[str] = Field(..., description="Lista de productos utilizados (ej: Cloro granulado, Reductor pH)")
    cantidades: list[str] = Field(..., description="Cantidades correspondientes a cada producto (ej: 500g, 1L)")
    fecha: datetime = Field(default_factory=datetime.utcnow, description="Fecha y hora del mantenimiento")


class Mantencion(MantencionIn):
    """
    Modelo persistido de mantenimiento.
    Incluye el username del técnico que realizó la acción.
    """
    username: str = Field(..., description="Nombre de usuario del técnico")
    creado_en: datetime = Field(default_factory=datetime.utcnow)
