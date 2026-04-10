"""
Script de carga masiva para las colecciones 'pools' y 'lecturas' en MongoDB Atlas.
Población de datos de prueba realistas para el proyecto CleanPool.

Uso:
    python seed.py                  # Ejecuta limpieza + carga de datos
    python seed.py --clean-only     # Solo limpia las lecturas previas
    python seed.py --no-clean       # Carga sin limpiar (permite duplicados)
"""

import sys
from datetime import datetime, timezone, timedelta
from pymongo.errors import PyMongoError

from db import get_db
from config import get_settings
from core.config_pool import evaluar_sensor, EstadoAgua


# Configuración de datos de prueba
POOL_ID = "piscina_test_01"
USERNAME_SEED = "seed_user"  # Usuario propietario del pool de prueba

# Configuración de la piscina
POOL_CONFIG = {
    "pool_id": POOL_ID,
    "nombre": "Piscina Principal (Test)",
    "volumen_m3": 50.0,
    "activo": True,
    "username": USERNAME_SEED,  # ✅ Asociar a usuario propietario
}

# 3 ESCENARIOS DE PRUEBA
ESCENARIOS = {
    "OPTIMO": {
        "ph": 7.5,
        "cloro": 2.0,
        "temperatura": 26.0,
        "conductividad": 1500.0,
    },
    "ADVERTENCIA": {
        "ph": 7.0,           # En rango advertencia (6.8-7.2)
        "cloro": 0.5,        # En rango advertencia (0.5)
        "temperatura": 26.0, # Óptimo
        "conductividad": 500.0,  # En rango advertencia (500)
    },
    "CRITICO": {
        "ph": 5.0,           # Fuera de rango (< 6.8)
        "cloro": 0.1,        # Fuera de rango (< 0.5)
        "temperatura": 38.0, # Fuera de rango (> 34.0)
        "conductividad": 4000.0,  # Fuera de rango (> 3000)
    }
}


def limpiar_pools(db, pool_id: str, username: str = None) -> int:
    """
    Elimina la configuración de un pool.
    Si username se proporciona, solo elimina el pool de ese usuario.
    Si no, elimina todos los pools con ese pool_id.
    
    Args:
        db: Instancia de base de datos MongoDB
        pool_id: ID del pool a limpiar
        username: (Opcional) Usuario propietario. Si se omite, limpia todos.
        
    Returns:
        Número de documentos eliminados
    """
    try:
        filter_query = {"pool_id": pool_id}
        if username:
            filter_query["username"] = username
        
        result = db.pools.delete_many(filter_query)
        if result.deleted_count > 0:
            user_str = f" de usuario '{username}'" if username else ""
            print(f"✓ Pool '{pool_id}'{user_str} eliminado (limpieza)")
        return result.deleted_count
    except PyMongoError as e:
        print(f"✗ Error eliminando pool: {str(e)}")
        raise


def crear_pool(db, pool_config: dict) -> bool:
    """
    Crea o actualiza la configuración de un pool.
    Usa composite key (pool_id, username) para unicidad per-usuario.
    
    Args:
        db: Instancia de base de datos MongoDB
        pool_config: Dict con pool_id, nombre, volumen_m3, activo, username
        
    Returns:
        True si se creó/actualizó exitosamente
    """
    try:
        pool_config = pool_config.copy()
        pool_config["creado_en"] = datetime.now(timezone.utc)
        pool_config["actualizado_en"] = None
        
        # ✅ Usar upsert con composite key (pool_id, username) para per-user unicidad
        result = db.pools.update_one(
            {
                "pool_id": pool_config["pool_id"],
                "username": pool_config["username"]
            },
            {"$set": pool_config},
            upsert=True
        )
        
        print(f"✓ Pool '{pool_config['pool_id']}' configurado para usuario '{pool_config['username']}': {pool_config['nombre']} ({pool_config['volumen_m3']} m³)")
        return True
        
    except PyMongoError as e:
        print(f"✗ Error creando pool: {str(e)}")
        raise


def limpiar_lecturas(db, pool_id: str) -> int:
    """
    Elimina todas las lecturas previas para un pool_id.
    
    Args:
        db: Instancia de base de datos MongoDB
        pool_id: ID de la piscina a limpiar
        
    Returns:
        Número de documentos eliminados
    """
    try:
        result = db.lecturas.delete_many({"pool_id": pool_id})
        print(f"✓ Limpieza completada: {result.deleted_count} lecturas eliminadas para '{pool_id}'")
        return result.deleted_count
    except PyMongoError as e:
        print(f"✗ Error durante limpieza: {str(e)}")
        raise


def generar_lecturas(pool_id: str) -> list:
    """
    Genera 10 lecturas de prueba distribuidas en los últimos 3 días.
    Cada lectura incluye el campo is_critical calculado según los rangos de config_pool.
    
    Distribución:
    - 4 lecturas ÓPTIMO (hace 3, 2.5, 2, 1.5 días)
    - 4 lecturas ADVERTENCIA (hace 1.2, 1, 0.8, 0.5 días)
    - 2 lecturas CRÍTICO (hace 0.3 y 0.05 días - la más reciente es CRÍTICO)
    
    Args:
        pool_id: ID de la piscina
        
    Returns:
        Lista de documentos listos para insertar
    """
    lecturas = []
    ahora = datetime.now(timezone.utc)
    
    # Cronograma de lecturas (en horas desde ahora hacia atrás)
    horarios = [
        (72, "OPTIMO"),      # 3 días atrás
        (60, "OPTIMO"),      # 2.5 días atrás
        (48, "OPTIMO"),      # 2 días atrás
        (36, "OPTIMO"),      # 1.5 días atrás
        (29, "ADVERTENCIA"), # 1.2 días atrás
        (24, "ADVERTENCIA"), # 1 día atrás
        (19, "ADVERTENCIA"), # 0.8 días atrás
        (12, "ADVERTENCIA"), # 0.5 días atrás
        (7, "CRITICO"),      # 0.3 días atrás (7.2 horas)
        (1, "CRITICO"),      # 1 hora atrás - LA MÁS RECIENTE
    ]
    
    for horas_atras, escenario in horarios:
        timestamp = ahora - timedelta(hours=horas_atras)
        valores = ESCENARIOS[escenario].copy()
        
        # Evaluar cada sensor para determinar criticidad
        evaluaciones = {
            "ph": evaluar_sensor("ph", valores["ph"]),
            "cloro": evaluar_sensor("cloro", valores["cloro"]),
            "temperatura": evaluar_sensor("temperatura", valores["temperatura"]),
            "conductividad": evaluar_sensor("conductividad", valores["conductividad"]),
        }
        
        # is_critical = True si CUALQUIER sensor está en CRÍTICO
        es_critico = any(
            eval_result["estado"] == EstadoAgua.CRITICO
            for eval_result in evaluaciones.values()
        )
        
        lectura = {
            "pool_id": pool_id,
            "ph": valores["ph"],
            "cloro": valores["cloro"],
            "temperatura": valores["temperatura"],
            "conductividad": valores["conductividad"],
            "timestamp": timestamp,
            "is_critical": es_critico,  # Bandera de criticidad persistida
        }
        lecturas.append(lectura)
        
        # Log para debugging con indicador de criticidad
        critical_marker = " 🚨 CRÍTICO" if es_critico else ""
        print(f"  [{escenario:12}] {timestamp.isoformat()} → "
              f"pH={valores['ph']}, Cl={valores['cloro']}, "
              f"T={valores['temperatura']}°C, Cond={valores['conductividad']}µS"
              f"{critical_marker}")
    
    return lecturas


def insertar_lecturas(db, lecturas: list) -> int:
    """
    Inserta los documentos en la colección 'lecturas'.
    
    Args:
        db: Instancia de base de datos MongoDB
        lecturas: Lista de documentos a insertar
        
    Returns:
        Número de documentos insertados
    """
    try:
        result = db.lecturas.insert_many(lecturas)
        print(f"✓ Inserción completada: {len(result.inserted_ids)} lecturas cargadas")
        return len(result.inserted_ids)
    except PyMongoError as e:
        print(f"✗ Error durante inserción: {str(e)}")
        raise


def main():
    """Función principal del script de carga masiva."""
    
    # Parsear argumentos de línea de comandos
    clean_only = "--clean-only" in sys.argv
    no_clean = "--no-clean" in sys.argv
    
    print("=" * 70)
    print("SEED.PY — Carga Masiva de Datos de Prueba para CleanPool")
    print("=" * 70)
    
    try:
        # Conectar a la base de datos
        settings = get_settings()
        db = get_db()
        
        print(f"\nConectado a MongoDB Atlas")
        print(f"Base de datos: {settings.database_name}")
        print(f"Pool ID: {POOL_ID}\n")
        
        # Limpieza de datos previos (si aplica)
        if clean_only:
            limpiar_lecturas(db, POOL_ID)
            limpiar_pools(db, POOL_ID)
            print("\nModo --clean-only: Terminando después de limpieza.")
            return
        
        if not no_clean:
            limpiar_lecturas(db, POOL_ID)
            limpiar_pools(db, POOL_ID)
        else:
            print("⚠️  Modo --no-clean: No se limpiarán datos previos (riesgo de duplicados)\n")
        
        # Crear configuración de pool
        print("\nConfigurando piscina:")
        crear_pool(db, POOL_CONFIG)
        
        # Generar datos de prueba
        print("Generando 10 lecturas de prueba:\n")
        lecturas = generar_lecturas(POOL_ID)
        
        # Insertar en MongoDB
        print("\nInsertando en MongoDB...")
        insertar_lecturas(db, lecturas)
        
        print("\n" + "=" * 70)
        print("✅ SEED COMPLETADO CON ÉXITO")
        print("=" * 70)
        print("\n📋 Próximos pasos:")
        print("  1. Abre Swagger en http://localhost:8000/docs")
        print("  2. Prueba GET /lecturas/estado?pool_id=piscina_test_01")
        print("  3. Deberías ver la lectura más reciente (CRÍTICO)")
        print("\n")
        
    except Exception as e:
        print(f"\n❌ ERROR: {str(e)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
