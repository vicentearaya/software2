import math

PI = math.pi

def calcular_volumen(forma: str, dimensiones: dict) -> float:
    """
    Recalcula el volumen de la piscina en metros cúbicos (m3) basado en su forma y dimensiones.
    
    Formas soportadas:
    - rectangular: requiere largo, ancho, profundidad
    - circular: requiere diametro, profundidad
    - oval: requiere eje_largo, eje_corto, profundidad
    - volumen_conocido: requiere volumen
    """
    if forma == "volumen_conocido":
        return float(dimensiones.get("volumen", 0.0))
        
    elif forma == "circular":
        diametro = float(dimensiones.get("diametro", 0.0))
        profundidad = float(dimensiones.get("profundidad", 0.0))
        radio = diametro / 2.0
        return PI * radio * radio * profundidad
        
    elif forma == "oval":
        eje_largo = float(dimensiones.get("eje_largo", 0.0))
        eje_corto = float(dimensiones.get("eje_corto", 0.0))
        profundidad = float(dimensiones.get("profundidad", 0.0))
        # Fórmula volumen óvalo: pi * (eje_largo / 2) * (eje_corto / 2) * profundidad
        return PI * (eje_largo / 2.0) * (eje_corto / 2.0) * profundidad
        
    elif forma == "rectangular":
        largo = float(dimensiones.get("largo", 0.0))
        ancho = float(dimensiones.get("ancho", 0.0))
        profundidad = float(dimensiones.get("profundidad", 0.0))
        return largo * ancho * profundidad
        
    else:
        raise ValueError(f"Forma de piscina no reconocida o no soportada: {forma}")
