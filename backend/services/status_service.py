"""
status_service.py — Servicio de Evaluación de Aptitud Global de Piscina

Módulo responsable de evaluar si una piscina es APTA o NO APTA para su uso
basándose en el estado de todos sus sensores.

Regla de Negocio (Tarea #61 - US-8):
  - Piscina APTA: Todos los sensores en estado OPTIMO o ADVERTENCIA
  - Piscina NO APTA: Al menos UN sensor en estado CRITICO

Importa el Enum EstadoAgua desde config_pool.py (no redefinir).
"""

from typing import Optional
from core.config_pool import EstadoAgua


def evaluar_aptitud_global(
    evaluaciones: dict[str, dict]
) -> dict:
    """
    Evalúa la aptitud global de una piscina basándose en el estado de sus sensores.

    Args:
        evaluaciones (dict): Diccionario con estructura:
            {
                "ph": {"valor": float, "estado": str, ...},
                "temperatura": {"valor": float, "estado": str, ...},
                "cloro": {"valor": float, "estado": str, ...},
                "conductividad": {"valor": float, "estado": str, ...}
            }
            donde "estado" es un valor del Enum EstadoAgua (OPTIMO, ADVERTENCIA, CRITICO)

    Returns:
        dict: Diccionario con estructura:
            {
                "piscina_apta": bool,  # True si TODOS están en OPTIMO/ADVERTENCIA
                "sensores_criticos": list[str],  # Nombres de sensores en estado CRITICO
                "motivo": str  # Texto descriptivo del estado
            }

    Lógica:
        - Si AL MENOS UN sensor tiene estado == CRITICO → piscina_apta = False
        - Si TODOS los sensores tienen estado == OPTIMO o ADVERTENCIA → piscina_apta = True
        - Maneja gracefully sensores offline (valor None o estado ausente)
    """

    # Validar que evaluaciones no esté vacío
    if not evaluaciones:
        return {
            "piscina_apta": False,
            "sensores_criticos": [],
            "motivo": "No hay datos de sensores disponibles. Verifica la conexión del ESP8266."
        }

    # Lista para almacenar sensores en estado crítico
    sensores_criticos: list[str] = []

    # Iterar sobre cada sensor y verificar su estado
    for nombre_sensor, eval_data in evaluaciones.items():
        # Manejar el caso donde el sensor no tenga datos o esté offline
        if eval_data is None or not isinstance(eval_data, dict):
            # Si el sensor está offline, se considera crítico por seguridad
            sensores_criticos.append(nombre_sensor)
            continue

        # Obtener el estado del sensor (convertir string a Enum si es necesario)
        estado_str = eval_data.get("estado")

        # Comparar con el Enum CRITICO
        if estado_str == EstadoAgua.CRITICO or estado_str == EstadoAgua.CRITICO.value:
            sensores_criticos.append(nombre_sensor)

    # Determinar aptitud global
    piscina_apta = len(sensores_criticos) == 0

    # Construir mensaje descriptivo
    if piscina_apta:
        motivo = "Piscina en condiciones APTAS para usar. Todos los sensores en rango óptimo o advertencia."
    else:
        sensores_lista = ", ".join(sensores_criticos)
        if len(sensores_criticos) == 1:
            motivo = f"⚠️  PISCINA NO APTA — Sensor {sensores_lista} en estado CRÍTICO. Toma acción inmediata."
        else:
            motivo = f"⚠️  PISCINA NO APTA — Sensores {sensores_lista} en estado CRÍTICO. Toma acción inmediata."

    return {
        "piscina_apta": piscina_apta,
        "sensores_criticos": sensores_criticos,
        "motivo": motivo
    }
