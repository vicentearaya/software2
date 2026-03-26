"""
⚠️  DEPRECADO — Este módulo NO DEBE USARSE

Este archivo contenía lógica duplicada de cálculos químicos.

**NUEVO ENFOQUE (Sprint 2+):**
- Usar `services/calculator.py` para lógica pura de dosificación
- Ese módulo es agnóstico a BD y retorna: 
  {"producto", "cantidad", "unidad", "instrucciones"}
- El frontend (Flutter) espera esas claves exactas

**Razón de deprecación:**
- Este archivo usaba interfaz diferente: {"quimico", "dosis_gramos", "formato", ...}
- Causaba mismatch con React/Flutter que esperaban {"producto", "cantidad", ...}
- Doblaba el mantenimiento sin beneficio

**Histórico:**
- Este módulo se mantuvo por compatibilidad con endpoint readings.py
- readings.py ha sido LIMPIADO — usar GET /api/v1/lecturas/estado en su lugar

Mientras se complete la migración total, este archivo se mantiene
para evitar ImportError, pero sus funciones NO DEBEN INVOCARSE.
"""

__deprecated__ = True
__reason__ = "Use services/calculator.py instead"
DOSIS_CONSTANTES = {
    "ph": {
        "bajo": {
            "quimico": "Carbonato de Sodio (Soda Ash)",
            "formato": "polvo",
            # Para subir 0.1 pH en 10 m³: 200 gramos
            "gramos_por_m3_delta01": 20.0,
        },
        "alto": {
            "quimico": "Bisulfato de Sodio (pH Down)",
            "formato": "polvo",
            # Para bajar 0.1 pH en 10 m³: 100 gramos
            "gramos_por_m3_delta01": 10.0,
        }
    },
    "cloro": {
        "bajo": {
            "quimico": "Cloro Granulado / Pastillas",
            "formato": "pastillas",
            # Para subir 1.0 ppm en 10 m³: 150 gramos
            "gramos_por_m3_delta1ppm": 15.0,
        }
    },
    "temperatura": {
        "nota": "Sin acción química. Verificar calefactor/bomba"
    },
    "conductividad": {
        "bajo": {
            "quimico": "Sal para Piscina",
            "formato": "bolsas",
            # Para subir 100 µS/cm en 10 m³: 500 gramos
            "gramos_por_m3_delta100us": 50.0,
        },
        "alto": {
            "accion": "Cambio parcial de agua (20-30%)",
            "nota": "No hay químico para bajar, dilución es la única opción"
        }
    }
}


def calcular_dosis_ph(pool_id: str, valor_actual: float, 
                      db: Database, rango_optimo_min: float = 7.2, 
                      rango_optimo_max: float = 7.8) -> Optional[Dict]:
    """
    Calcula la dosis de químico para ajustar pH al rango óptimo.
    
    Args:
        pool_id: ID de la piscina
        valor_actual: Valor actual de pH
        db: Instancia de MongoDB
        rango_optimo_min: Límite inferior del rango óptimo (default: 7.2)
        rango_optimo_max: Límite superior del rango óptimo (default: 7.8)
    
    Returns:
        Dict con recomendación: {"quimico", "dosis_gramos", "instruccion"}
        None si pH ya está en rango óptimo
    
    Raises:
        ValueError: Si pool_id no existe en BD
    """
    # Consultar volumen de la piscina
    pool = db.pools.find_one({"pool_id": pool_id})
    if not pool:
        raise ValueError(f"Pool '{pool_id}' no configurado en BD. "
                        "Primero crear con POST /pools")
    
    volumen_m3 = pool.get("volumen_m3")
    if not volumen_m3 or volumen_m3 <= 0:
        raise ValueError(f"Pool '{pool_id}' tiene volumen inválido: {volumen_m3}")
    
    # Verificar si está en rango
    if rango_optimo_min <= valor_actual <= rango_optimo_max:
        return None  # Ya está bien
    
    # Calcular desviación
    if valor_actual < rango_optimo_min:
        # pH BAJO: Usar Carbonato de Sodio (subir)
        delta_ph = rango_optimo_min - valor_actual
        quimico_config = DOSIS_CONSTANTES["ph"]["bajo"]
        dosis_gramos = delta_ph * quimico_config["gramos_por_m3_delta01"] * volumen_m3
        
        return {
            "quimico": quimico_config["quimico"],
            "formato": quimico_config["formato"],
            "dosis_gramos": round(dosis_gramos, 1),
            "delta_ph": round(delta_ph, 2),
            "instruccion": (
                f"Disolver {dosis_gramos:.0f}g de {quimico_config['quimico']} "
                f"en agua, distribuir uniformemente por la piscina. "
                f"Esperar 1 hora, re-verificar con kit de prueba."
            ),
            "precauciones": "Usar guantes. Evitar inhalación de polvo."
        }
    
    else:  # valor_actual > rango_optimo_max
        # pH ALTO: Usar Bisulfato de Sodio (bajar)
        delta_ph = valor_actual - rango_optimo_max
        quimico_config = DOSIS_CONSTANTES["ph"]["alto"]
        dosis_gramos = delta_ph * quimico_config["gramos_por_m3_delta01"] * volumen_m3
        
        return {
            "quimico": quimico_config["quimico"],
            "formato": quimico_config["formato"],
            "dosis_gramos": round(dosis_gramos, 1),
            "delta_ph": round(delta_ph, 2),
            "instruccion": (
                f"Disolver {dosis_gramos:.0f}g de {quimico_config['quimico']} "
                f"en agua, distribuir uniformemente por la piscina. "
                f"Esperar 30 minutos, re-verificar con kit de prueba."
            ),
            "precauciones": "Ácido débil. Usar guantes y gafas de protección."
        }


def calcular_dosis_cloro(pool_id: str, valor_actual: float, 
                         db: Database, rango_optimo_min: float = 1.0,
                         rango_optimo_max: float = 3.0) -> Optional[Dict]:
    """
    Calcula la dosis de cloro para alcanzar rango óptimo.
    
    Args:
        pool_id: ID de la piscina
        valor_actual: Valor actual en ppm
        db: Instancia de MongoDB
        rango_optimo_min: Mínimo recomendado (default: 1.0 ppm)
        rango_optimo_max: Máximo recomendado (default: 3.0 ppm)
    
    Returns:
        Dict con recomendación o None si ya está en rango
    """
    pool = db.pools.find_one({"pool_id": pool_id})
    if not pool:
        raise ValueError(f"Pool '{pool_id}' no configurado")
    
    volumen_m3 = pool.get("volumen_m3")
    if not volumen_m3 or volumen_m3 <= 0:
        raise ValueError(f"Volumen inválido para pool '{pool_id}'")
    
    # Si está en rango, no hacer nada
    if rango_optimo_min <= valor_actual <= rango_optimo_max:
        return None
    
    # Si está bajo, aumentar
    if valor_actual < rango_optimo_min:
        delta_ppm = rango_optimo_min - valor_actual
        quimico_config = DOSIS_CONSTANTES["cloro"]["bajo"]
        dosis_gramos = delta_ppm * quimico_config["gramos_por_m3_delta1ppm"] * volumen_m3
        
        return {
            "quimico": quimico_config["quimico"],
            "formato": quimico_config["formato"],
            "dosis_gramos": round(dosis_gramos, 1),
            "delta_ppm": round(delta_ppm, 2),
            "instruccion": (
                f"Colocar {dosis_gramos:.0f}g de {quimico_config['quimico']} "
                f"en el skimmer o flotador de dosificación. "
                f"Dejar actuar 2-4 horas. Re-verificar antes de usar la piscina."
            ),
            "precauciones": "Producto cáustico. No mezclar con otros químicos."
        }
    
    else:  # valor_actual > rango_optimo_max
        # Cloro ALTO: No hay químico. Solo esperar o diluir
        delta_ppm = valor_actual - rango_optimo_max
        
        return {
            "quimico": "Ninguno (Espera o Dilución)",
            "accion": "Esperar a que se disipe naturalmente o cambiar agua parcial (20%)",
            "delta_ppm": round(delta_ppm, 2),
            "instruccion": (
                f"Cloro demasiado alto (+{delta_ppm:.2f} ppm). "
                f"Opciones:\n"
                f"1. Apagar circulación y esperar 6-12 horas (evaporación)\n"
                f"2. Cambiar {round(delta_ppm * 3.5)}% del agua\n"
                f"3. Usar neutralizante de cloro (Tiosulfato de Sodio)"
            ),
            "precauciones": "NO entrar a la piscina hasta que baje a < 3.0 ppm"
        }


def calcular_dosis_conductividad(pool_id: str, valor_actual: float,
                                  db: Database, rango_optimo_min: float = 1000.0,
                                  rango_optimo_max: float = 2000.0) -> Optional[Dict]:
    """
    Calcula dosis de sal para piscinas (conductividad).
    
    Args:
        pool_id: ID de la piscina
        valor_actual: Conductividad en µS/cm
        db: Instancia de MongoDB
    
    Returns:
        Dict con recomendación o None
    """
    pool = db.pools.find_one({"pool_id": pool_id})
    if not pool:
        raise ValueError(f"Pool '{pool_id}' no configurado")
    
    volumen_m3 = pool.get("volumen_m3")
    if not volumen_m3 or volumen_m3 <= 0:
        raise ValueError(f"Volumen inválido para pool '{pool_id}'")
    
    # Si está en rango, OK
    if rango_optimo_min <= valor_actual <= rango_optimo_max:
        return None
    
    # Si está bajo, agregar sal
    if valor_actual < rango_optimo_min:
        delta_us = rango_optimo_min - valor_actual
        quimico_config = DOSIS_CONSTANTES["conductividad"]["bajo"]
        dosis_gramos = (delta_us / 100.0) * quimico_config["gramos_por_m3_delta100us"] * volumen_m3
        
        return {
            "quimico": quimico_config["quimico"],
            "dosis_gramos": round(dosis_gramos, 1),
            "delta_us_cm": round(delta_us, 0),
            "instruccion": (
                f"Agregar {dosis_gramos:.0f}g de sal de piscina (NaCl puro). "
                f"Distribuir alrededor del perímetro con circulación activa. "
                f"Esperar 2-3 horas, re-verificar."
            ),
            "precauciones": "Usar solo sal de piscina purificada. "
                          "No usar sal de cocina (contiene aditivos)."
        }
    
    else:  # valor_actual > rango_optimo_max
        # Conductividad Alta: Solo dilución posible
        delta_us = valor_actual - rango_optimo_max
        porcentaje_cambio = round((delta_us / valor_actual) * 100)
        
        return {
            "quimico": "Ninguno (Solo dilución)",
            "accion": "Cambio parcial o total de agua",
            "delta_us_cm": round(delta_us, 0),
            "instruccion": (
                f"Conductividad demasiado alta. "
                f"Cambiar aproximadamente {porcentaje_cambio}% del volumen de agua "
                f"(~{round(volumen_m3 * porcentaje_cambio / 100)}m³). "
                f"Usar agua destilada o de lluvia si es posible."
            ),
            "precauciones": "No hay químico que baje conductividad. "
                          "Solo dilución con agua pura."
        }


def calcular_recomendaciones_completas(pool_id: str, db: Database,
                                       evaluaciones: Dict) -> Dict:
    """
    Genera recomendaciones químicas completas basadas en evaluaciones de sensores.
    
    Args:
        pool_id: ID de la piscina
        db: Instancia de MongoDB
        evaluaciones: Dict retornado por GET /lecturas/estado
                     {"ph": {...}, "cloro": {...}, ...}
    
    Returns:
        Dict con recomendaciones por sensor
        
    Ejemplo:
        {
          "ph": {"quimico": "...", "dosis_gramos": 150.0, "instruccion": "..."},
          "cloro": None,  # Si está en rango
          "temperatura": {"accion": "Verificar calefactor", ...}
        }
    """
    recomendaciones = {}
    
    # Procesar pH
    try:
        ph_valor = evaluaciones.get("ph", {}).get("valor")
        if ph_valor:
            recomendaciones["ph"] = calcular_dosis_ph(pool_id, ph_valor, db)
    except ValueError as e:
        recomendaciones["ph"] = {"error": str(e)}
    
    # Procesar Cloro
    try:
        cloro_valor = evaluaciones.get("cloro", {}).get("valor")
        if cloro_valor:
            recomendaciones["cloro"] = calcular_dosis_cloro(pool_id, cloro_valor, db)
    except ValueError as e:
        recomendaciones["cloro"] = {"error": str(e)}
    
    # Procesar Conductividad
    try:
        cond_valor = evaluaciones.get("conductividad", {}).get("valor")
        if cond_valor:
            recomendaciones["conductividad"] = calcular_dosis_conductividad(
                pool_id, cond_valor, db
            )
    except ValueError as e:
        recomendaciones["conductividad"] = {"error": str(e)}
    
    # Temperatura (no hay acción química, solo verificación)
    temp_valor = evaluaciones.get("temperatura", {}).get("valor")
    if temp_valor:
        if temp_valor < 20:
            recomendaciones["temperatura"] = {
                "accion": "Verificar calefactor",
                "instruccion": "Temperatura baja. Activar o revisar sistema de calefacción."
            }
        elif temp_valor > 34:
            recomendaciones["temperatura"] = {
                "accion": "Aumentar circulación",
                "instruccion": "Temperatura alta. Aumentar velocidad de bomba o agregar sombra."
            }
    
    return recomendaciones
