#!/usr/bin/env python
"""
Script de verificación para auditar el campo is_critical en MongoDB.
Verifica que la última lectura insertada tenga la bandera correcta.

Uso:
    python verify_critical_flag.py
"""

from db import get_db
from config import get_settings
from datetime import datetime, timezone

def main():
    """Verifica el campo is_critical en la última lectura."""
    
    try:
        settings = get_settings()
        db = get_db()
        
        # Obtener la última lectura (más reciente)
        ultima_lectura = db.lecturas.find_one(
            sort=[("timestamp", -1)]
        )
        
        if not ultima_lectura:
            print("❌ No hay lecturas en la colección 'lecturas'")
            return
        
        # Extraer información relevante
        pool_id = ultima_lectura.get("pool_id", "N/A")
        timestamp = ultima_lectura.get("timestamp", "N/A")
        is_critical = ultima_lectura.get("is_critical", None)
        ph = ultima_lectura.get("ph", "N/A")
        cloro = ultima_lectura.get("cloro", "N/A")
        temperatura = ultima_lectura.get("temperatura", "N/A")
        conductividad = ultima_lectura.get("conductividad", "N/A")
        
        print("=" * 70)
        print("🔍 VERIFICACIÓN — Campo is_critical en MongoDB")
        print("=" * 70)
        
        print(f"\n📊 Última Lectura Insertada:")
        print(f"  Pool ID: {pool_id}")
        print(f"  Timestamp: {timestamp}")
        print(f"  pH: {ph}")
        print(f"  Cloro: {cloro}")
        print(f"  Temperatura: {temperatura}")
        print(f"  Conductividad: {conductividad}")
        
        print(f"\n🚨 Estado de Criticidad:")
        if is_critical is None:
            print(f"  ❌ FALLO: Campo 'is_critical' NO EXISTE en la lectura")
            print(f"     Verifica que ingesta.py agregue el campo antes de insertar")
        elif is_critical is True:
            print(f"  ✅ CRÍTICO: is_critical = {is_critical}")
            print(f"     La piscina está en estado NO APTO")
        elif is_critical is False:
            print(f"  ✅ ÓPTIMO: is_critical = {is_critical}")
            print(f"     La piscina está en estado APTO")
        else:
            print(f"  ⚠️  TIPO INVÁLIDO: is_critical = {is_critical} ({type(is_critical)})")
        
        # Estadísticas adicionales
        print(f"\n📈 Estadísticas de la Colección:")
        
        total_lecturas = db.lecturas.count_documents({"pool_id": pool_id})
        lecturas_criticas = db.lecturas.count_documents({
            "pool_id": pool_id,
            "is_critical": True
        })
        lecturas_optimas = db.lecturas.count_documents({
            "pool_id": pool_id,
            "is_critical": False
        })
        
        print(f"  Total de lecturas (pool '{pool_id}'): {total_lecturas}")
        print(f"  Lecturas en estado CRÍTICO: {lecturas_criticas}")
        print(f"  Lecturas en estado ÓPTIMO: {lecturas_optimas}")
        
        if total_lecturas > 0:
            porcentaje_critico = (lecturas_criticas / total_lecturas) * 100
            print(f"  Porcentaje CRÍTICO: {porcentaje_critico:.1f}%")
        
        print("\n" + "=" * 70)
        if is_critical is not None:
            print("✅ VERIFICACIÓN EXITOSA — Campo is_critical está bien persistido")
        else:
            print("❌ VERIFICACIÓN FALLIDA — Campo is_critical falta en MongoDB")
        print("=" * 70)
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        print(f"   Verifica que MongoDB Atlas esté accesible y .env esté configurado")

if __name__ == "__main__":
    main()
