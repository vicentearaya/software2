"""
calculator.py — Módulo puro de cálculo de dosificación química

Este módulo contiene lógica pura (sin BD, sin FastAPI) para calcular
la cantidad de químicos necesarios para ajustar parámetros de agua.

No tiene dependencias externas. Solo librería estándar.
"""


def calcular_dosis(sensor: str, current_val: float, target_val: float, volumen_m3: float) -> dict:
    """
    Calcula la cantidad de químico necesario para alcanzar el valor objetivo.
    
    Soporta: pH y cloro.
    
    Args:
        sensor (str): Tipo de sensor. Valores válidos: "ph", "cloro"
        current_val (float): Valor actual medido por el sensor
        target_val (float): Valor objetivo a alcanzar
        volumen_m3 (float): Volumen de la piscina en metros cúbicos (> 0)
    
    Returns:
        dict: {
            "producto": str,           # Nombre del químico a usar
            "cantidad": float,         # Cantidad redondeada a 1 decimal
            "unidad": str,             # Siempre "gr" (gramos)
            "instrucciones": str       # Instrucciones de aplicación
        }
    
    Raises:
        ValueError: Si volumen_m3 <= 0 o sensor no soportado
    
    Ejemplos:
        >>> calcular_dosis("ph", 8.0, 7.5, 50.0)
        {
            'producto': 'Bisulfato de Sodio (reductor de pH)',
            'cantidad': 4500.0,
            'unidad': 'gr',
            'instrucciones': 'Disolver en agua antes de aplicar'
        }
        
        >>> calcular_dosis("cloro", 0.5, 2.0, 50.0)
        {
            'producto': 'Cloro granulado (hipoclorito de calcio 65%)',
            'cantidad': 115384.6,
            'unidad': 'gr',
            'instrucciones': 'Agregar gradualmente al skimmer'
        }
    """
    
    # VALIDACIONES
    if volumen_m3 <= 0:
        raise ValueError("El volumen debe ser mayor a cero.")
    
    if sensor not in ("ph", "cloro"):
        raise ValueError(f"Sensor '{sensor}' no soportado para dosificación.")
    
    # CASO: Sin acción requerida
    if current_val == target_val:
        return {
            "producto": "Sin acción requerida",
            "cantidad": 0,
            "unidad": "gr",
            "instrucciones": "Parámetro en valor objetivo."
        }
    
    # ====== CÁLCULOS PARA pH ======
    if sensor == "ph":
        if current_val > target_val:
            # pH ALTO: Usar Bisulfato de Sodio (reductor)
            delta = current_val - target_val
            cantidad_gr = delta * volumen_m3 * 180
            
            return {
                "producto": "Bisulfato de Sodio (reductor de pH)",
                "cantidad": round(cantidad_gr, 1),
                "unidad": "gr",
                "instrucciones": "Disolver en agua antes de aplicar"
            }
        
        else:  # current_val < target_val
            # pH BAJO: Usar Carbonato de Sodio (incrementador)
            delta = target_val - current_val
            cantidad_gr = delta * volumen_m3 * 150
            
            return {
                "producto": "Carbonato de Sodio (incrementador de pH)",
                "cantidad": round(cantidad_gr, 1),
                "unidad": "gr",
                "instrucciones": "Disolver en agua antes de aplicar"
            }
    
    # ====== CÁLCULOS PARA CLORO ======
    elif sensor == "cloro":
        if current_val < target_val:
            # CLORO BAJO: Agregar
            delta = target_val - current_val
            cantidad_gr = (delta * volumen_m3 * 1000) / 0.65
            
            return {
                "producto": "Cloro granulado (hipoclorito de calcio 65%)",
                "cantidad": round(cantidad_gr, 1),
                "unidad": "gr",
                "instrucciones": "Agregar gradualmente al skimmer"
            }
        
        else:  # current_val > target_val
            # CLORO ALTO: Sin dosificación (reducción natural)
            return {
                "producto": "Sin dosificación necesaria — reducción natural",
                "cantidad": 0,
                "unidad": "gr",
                "instrucciones": "Esperar 6-12 horas para que el cloro se disipe naturalmente"
            }


# ============ PRUEBAS ============

if __name__ == "__main__":
    print("=" * 70)
    print("PRUEBAS — calcular_dosis()")
    print("=" * 70)
    
    # Caso 1: pH ALTO (reducción necesaria)
    print("\n[CASO 1] pH ALTO — Reducir pH de 8.0 a 7.5 en piscina de 50m³")
    resultado = calcular_dosis("ph", 8.0, 7.5, 50.0)
    print(f"  Producto: {resultado['producto']}")
    print(f"  Cantidad: {resultado['cantidad']} {resultado['unidad']}")
    print(f"  Instrucciones: {resultado['instrucciones']}")
    assert resultado["cantidad"] == 4500.0, "Error en cálculo pH alto"
    print("  ✓ PASADO")
    
    # Caso 2: pH BAJO (incremento necesario)
    print("\n[CASO 2] pH BAJO — Subir pH de 6.5 a 7.5 en piscina de 50m³")
    resultado = calcular_dosis("ph", 6.5, 7.5, 50.0)
    print(f"  Producto: {resultado['producto']}")
    print(f"  Cantidad: {resultado['cantidad']} {resultado['unidad']}")
    print(f"  Instrucciones: {resultado['instrucciones']}")
    assert resultado["cantidad"] == 7500.0, "Error en cálculo pH bajo"
    print("  ✓ PASADO")
    
    # Caso 3: CLORO BAJO (agregar)
    print("\n[CASO 3] CLORO BAJO — Subir cloro de 0.5 a 2.0 ppm en piscina de 50m³")
    resultado = calcular_dosis("cloro", 0.5, 2.0, 50.0)
    print(f"  Producto: {resultado['producto']}")
    print(f"  Cantidad: {resultado['cantidad']} {resultado['unidad']}")
    print(f"  Instrucciones: {resultado['instrucciones']}")
    # Cálculo: (2.0 - 0.5) * 50 * 1000 / 0.65 = 1.5 * 50 * 1000 / 0.65 = 115384.6
    assert resultado["cantidad"] == 115384.6, "Error en cálculo cloro bajo"
    print("  ✓ PASADO")
    
    # Caso 4: CLORO ALTO (sin acción)
    print("\n[CASO 4] CLORO ALTO — 5.0 ppm cuando objetivo es 2.0 (reducción natural)")
    resultado = calcular_dosis("cloro", 5.0, 2.0, 50.0)
    print(f"  Producto: {resultado['producto']}")
    print(f"  Cantidad: {resultado['cantidad']} {resultado['unidad']}")
    print(f"  Instrucciones: {resultado['instrucciones']}")
    assert resultado["cantidad"] == 0, "Error en cálculo cloro alto"
    print("  ✓ PASADO")
    
    # Caso 5: VOLUMEN CERO (error esperado)
    print("\n[CASO 5] VOLUMEN CERO — Validación de error")
    try:
        resultado = calcular_dosis("ph", 8.0, 7.5, 0)
        print("  ✗ FALLIDO — No lanzó excepción")
        exit(1)
    except ValueError as e:
        print(f"  Error capturado: {str(e)}")
        assert str(e) == "El volumen debe ser mayor a cero.", "Mensaje de error incorrecto"
        print("  ✓ PASADO")
    
    print("\n" + "=" * 70)
    print("✅ TODOS LOS CASOS PASARON")
    print("=" * 70)
