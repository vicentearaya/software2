"""
calculator.py — Módulo puro de cálculo de dosificación química

Este módulo contiene lógica pura (sin BD, sin FastAPI) para calcular
la cantidad de químicos necesarios para ajustar parámetros de agua,
enfocándose en reglas individuales y casos combinados.

No tiene dependencias externas. Solo librería estándar.
"""


def calcular_tratamiento(ph: float | None, cloro: float | None, volumen_m3: float) -> list[dict]:
    """
    Calcula el tratamiento necesario basándose en reglas específicas de control de agua
    para pH y cloro, considerando casos en que ambos estén fuera de rango.

    Args:
        ph (float | None): Valor actual de pH (None si no hay lectura)
        cloro (float | None): Valor actual de cloro en ppm (None si no hay lectura)
        volumen_m3 (float): Volumen de la piscina en metros cúbicos (> 0)

    Returns:
        list[dict]: Lista ordenada de acciones a realizar. Cada acción es:
            {
                "producto": str,
                "cantidad": float,
                "unidad": str,     # "gr", "ml", "N/A"
                "instrucciones": str
            }
    """
    if volumen_m3 <= 0:
        raise ValueError("El volumen debe ser mayor a cero.")

    tratamiento = []
    
    # Flags de estado para calcular combinaciones
    ph_status = "NORMAL"
    cloro_status = "NORMAL"
    
    if ph is not None:
        if ph < 6.8: ph_status = "MUY_BAJO"
        elif ph < 7.2: ph_status = "BAJO"
        elif ph > 8.0: ph_status = "MUY_ALTO"
        elif ph > 7.6: ph_status = "ALTO"
        
    if cloro is not None:
        if cloro < 0.5: cloro_status = "MUY_BAJO"
        elif cloro < 1.0: cloro_status = "BAJO"
        elif cloro > 5.0: cloro_status = "MUY_ALTO"
        elif cloro > 3.0: cloro_status = "ALTO"

    # Si todo es NORMAL (o no hay datos que requieran acción)
    if ph_status == "NORMAL" and cloro_status == "NORMAL":
        return [{
            "producto": "Ninguno",
            "cantidad": 0.0,
            "unidad": "N/A",
            "instrucciones": "El agua está en óptimas condiciones. Mantener monitoreo regular."
        }]

    # CASOS CON PRIORIDAD (Casos combinados)
    # Regla: pH FUERA DE RANGO + CLORO NORMAL -> Ajustar pH primero
    # Regla: pH BAJO/ALTO + CLORO BAJO -> Ajustar/Bajar pH primero, luego cloro
    
    accion_ph = None
    accion_cloro = None
    
    # 1. EVALUAR pH
    if ph is not None and ph_status != "NORMAL":
        # Target nominal de pH para cálculos es 7.4 (midpoint)
        target_ph = 7.4
        
        if ph_status in ["BAJO", "MUY_BAJO"]:
            delta = target_ph - ph
            # 150 g / 10.000 L -> sube ~0.2 pH
            cantidad_gr = (delta / 0.2) * (volumen_m3 / 10.0) * 150.0
            
            instruccion = "Aplicar en 1 a 3 dosis pequeñas." if ph_status == "BAJO" else "Aplicar en múltiples dosis de 300-500g. Esperar 4-6h entre aplicaciones."
            accion_ph = {
                "producto": "Elevador de pH (carbonato de sodio)",
                "cantidad": round(cantidad_gr, 1),
                "unidad": "gr",
                "instrucciones": instruccion
            }
        elif ph_status in ["ALTO", "MUY_ALTO"]:
            delta = ph - target_ph
            # 100 ml / 10.000 L -> baja ~0.2 pH
            cantidad_ml = (delta / 0.2) * (volumen_m3 / 10.0) * 100.0
            
            instruccion = "Aplicar en partes y esperar 4-6 h." if ph_status == "ALTO" else "Bajar pH de forma progresiva. Varias dosis (NO todo de una)."
            accion_ph = {
                "producto": "Reductor de pH (ácido muriático o bisulfato)",
                "cantidad": round(cantidad_ml, 1),
                "unidad": "ml",
                "instrucciones": instruccion
            }

    # 2. EVALUAR CLORO
    if cloro is not None and cloro_status != "NORMAL":
        target_cloro = 2.0  # Midpoint of 1.0 - 3.0
        
        if cloro_status in ["BAJO", "MUY_BAJO"]:
            delta = target_cloro - cloro
            # 10 g / 1.000 L -> sube ~1 ppm (10g por 1m3 por 1ppm)
            cantidad_gr = delta * volumen_m3 * 10.0
            
            if cloro_status == "BAJO":
                cantidad_gr = cantidad_gr * 0.50  # 50% de la dosis
                instruccion = "Ajuste leve (50% de la dosis calculada)."
            else:
                instruccion = "Aplicar dosis completa calculada y filtrar agua."
                
            accion_cloro = {
                "producto": "Cloro granulado",
                "cantidad": round(cantidad_gr, 1),
                "unidad": "gr",
                "instrucciones": instruccion
            }
            
        elif cloro_status == "ALTO":
            accion_cloro = {
                "producto": "Ninguno",
                "cantidad": 0.0,
                "unidad": "N/A",
                "instrucciones": "Cloro alto. No agregar cloro, esperar a que baje naturalmente. Exponer al sol."
            }
        elif cloro_status == "MUY_ALTO":
            accion_cloro = {
                "producto": "Ninguno",
                "cantidad": 0.0,
                "unidad": "N/A",
                "instrucciones": "Cloro MUY alto. Suspender uso de piscina. Esperar reducción natural, opcional: diluir con agua."
            }

    # 3. ORDENAMIENTO (Basado en Reglas Combinadas)
    if accion_ph and accion_cloro:
        # Siempre va pH primero
        accion_ph["instrucciones"] = f"Paso 1: {accion_ph['instrucciones']}"
        accion_cloro["instrucciones"] = f"Paso 2: {accion_cloro['instrucciones']}"
        
        tratamiento.append(accion_ph)
        tratamiento.append(accion_cloro)
    else:
        if accion_ph: tratamiento.append(accion_ph)
        if accion_cloro: tratamiento.append(accion_cloro)
        
    return tratamiento


# ============ PRUEBAS ============

if __name__ == "__main__":
    print("=" * 70)
    print("PRUEBAS — calcular_tratamiento()")
    print("=" * 70)
    
    def test_case(nombre, ph, cloro, m3):
        print(f"\\n[CASO] {nombre} (pH: {ph}, Cloro: {cloro}, Vol: {m3}m³)")
        resultado = calcular_tratamiento(ph, cloro, m3)
        for i, paso in enumerate(resultado):
            print(f"  Paso {i+1}:")
            print(f"    Producto: {paso['producto']}")
            print(f"    Cantidad: {paso['cantidad']} {paso['unidad']}")
            print(f"    Instrucciones: {paso['instrucciones']}")

    test_case("pH NORMAL + CLORO NORMAL", 7.4, 2.0, 50.0)
    test_case("pH BAJO + CLORO BAJO (Caso Combinado)", 6.8, 0.5, 50.0)
    test_case("pH ALTO + CLORO BAJO (Caso Combinado)", 7.8, 0.4, 10.0)
    test_case("pH NORMAL + CLORO ALTO", 7.4, 4.0, 60.0)
    test_case("pH MUY ALTO + CLORO MUY ALTO", 8.2, 6.0, 25.0)
    
    print("\\n" + "=" * 70)
    print("✅ TODOS LOS CASOS CORRIDOS")
    print("=" * 70)
