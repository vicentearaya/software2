import requests
import json

BASE_URL = "http://localhost:8000" # Asumimos local para el test

def test_status(pool_id):
    print(f"Probando estado para pool: {pool_id}")
    try:
        response = requests.get(f"{BASE_URL}/api/v1/pools/{pool_id}/status")
        if response.status_code == 200:
            print("ÉXITO:")
            print(json.dumps(response.json(), indent=2))
        else:
            print(f"FALLO: {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Error de conexión: {e}")

if __name__ == "__main__":
    # Nota: Este script requiere que el servidor esté corriendo
    # y que existan datos en la BD.
    # Se usará para pruebas manuales o integradas.
    test_status("dummy_id")
