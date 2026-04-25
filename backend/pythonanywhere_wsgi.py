import sys
import os

# 1. Ajusta esta ruta a donde alojaste tu proyecto en PythonAnywhere.
# Por ejemplo: '/home/TU_USUARIO/aplicacion_proyecto/backend'
path = '/home/tu_usuario_de_pythonanywhere/tu_proyecto/backend'
if path not in sys.path:
    sys.path.insert(0, path)

# 2. Instancia de FastAPI importada desde main.py
from main import app as asgi_app

# 3. Adaptador a2wsgi para convertir FastAPI (ASGI) a WSGI 
# requerido para las Web Apps de PythonAnywhere.
from a2wsgi import ASGIMiddleware

application = ASGIMiddleware(asgi_app)
