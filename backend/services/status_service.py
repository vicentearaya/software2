"""
status_service.py — Servicio de Evaluación de Aptitud Global de Piscina

Módulo responsable de evaluar si una piscina es APTA o NO APTA para su uso
basándose en el estado de todos sus sensores, y de recomendar tratamientos
al identificar anormalidades en pH y Cloro.

Regla de Negocio (Tarea #61 - US-8):
  - Piscina APTA: Todos los sensores en estado OPTIMO o ADVERTENCIA
  - Piscina NO APTA: Al menos UN sensor en estado CRITICO
"""

from typing import Optional
from core.config_pool import EstadoAgua
from services.calculator import calcular_tratamiento


def evaluar_aptitud_global(
    evaluaciones: dict[str, dict],
    volumen_m3: float = 0.0
) -> dict:
    """
    Evalúa la aptitud global de una piscina basándose en el estado de sus sensores
    y añade un plan de tratamiento si es necesario.

    Args:
        evaluaciones (dict): Diccionario con estructura:
            {
                "ph": {"valor": float, "estado": str, ...},
                "temperatura": {"valor": float, "estado": str, ...},
                "cloro": {"valor": float, "estado": str, ...},
                "conductividad": {"valor": float, "estado": str, ...}
            }
        volumen_m3 (float): Volumen de la piscina, necesario para calcular dosis de químicos.
                           Si es 0.0, no se devolverá plan de tratamiento.
                           
    Returns:
        dict: Diccionario con estructura:
            {
                "piscina_apta": bool,
                "sensores_criticos": list[str],
                "motivo": str,
                "tratamiento": list[dict]
            }
    """

    if not evaluaciones:
        return {
            "piscina_apta": False,
            "sensores_criticos": [],
            "motivo": "No hay datos de sensores disponibles. Verifica la conexión del ESP8266.",
            "tratamiento": []
        }

    sensores_criticos: list[str] = []

    for nombre_sensor, eval_data in evaluaciones.items():
        if eval_data is None or not isinstance(eval_data, dict):
            sensores_criticos.append(nombre_sensor)
            continue

        estado_str = eval_data.get("estado")
        if estado_str == EstadoAgua.CRITICO or estado_str == EstadoAgua.CRITICO.value:
            sensores_criticos.append(nombre_sensor)

    piscina_apta = len(sensores_criticos) == 0

    if piscina_apta:
        motivo = "Piscina en condiciones APTAS para usar. Todos los sensores en rango óptimo o advertencia."
    else:
        sensores_lista = ", ".join(sensores_criticos)
        if len(sensores_criticos) == 1:
            motivo = f"⚠️  PISCINA NO APTA — Sensor {sensores_lista} en estado CRÍTICO. Toma acción inmediata."
        else:
            motivo = f"⚠️  PISCINA NO APTA — Sensores {sensores_lista} en estado CRÍTICO. Toma acción inmediata."

    # ----- CÁLCULO DE TRATAMIENTO O DOSIFICACIÓN REQUERIDA -----
    tratamiento = []
    
    # Solo intentamos calcular dosis si nos mandan el volumen
    if volumen_m3 > 0.0:
        val_ph = None
        val_cloro = None
        
        ph_data = evaluaciones.get("ph")
        if isinstance(ph_data, dict):
            val_ph = ph_data.get("valor")
            
        cloro_data = evaluaciones.get("cloro")
        if isinstance(cloro_data, dict):
            val_cloro = cloro_data.get("valor")
            
        # Si tenemos al menos uno, calculamos
        if val_ph is not None or val_cloro is not None:
            try:
                tratamiento = calcular_tratamiento(val_ph, val_cloro, volumen_m3)
            except Exception as e:
                # Si falla el calculador interno, dejamos la lista vacía para no bloquear el dashboard
                print(f"Error calculando tratamiento: {e}")

    return {
        "piscina_apta": piscina_apta,
        "sensores_criticos": sensores_criticos,
        "motivo": motivo,
        "tratamiento": tratamiento
    }
