# CleanPool App

Sistema integral de monitoreo IoT para piscinas. Conecta sensores de estado del agua (vía un dispositivo Arduino/ESP8266) con una aplicación móvil construida en Flutter y un backend en FastAPI.

## Arquitectura y Tecnologías

El proyecto se divide en dos módulos principales:
- **Frontend**: Aplicación móvil multiplataforma desarrollada en **Flutter** (Dart).
- **Backend**: API REST desarrollada en **FastAPI** (Python) conectada a **MongoDB Atlas**.

---

## ⚙️ Dependencias y Requisitos Previos

Para poder ejecutar el proyecto necesitas tener instaladas en tu sistema las siguientes herramientas:

### Backend (Python / FastAPI)
- **Python** (versión recomendada 3.11 o superior).
- Entorno virtual (ej. `venv`).
- Las librerías detalladas en `backend/requirements.txt`. Las principales son:
  - `fastapi` y `uvicorn` (Servidor web y API)
  - `pymongo[srv]` (Conexión a base de datos de MongoDB)
  - `passlib[bcrypt]` y `python-jose[cryptography]` (Seguridad, autenticación y JWT)
  - `pydantic-settings`, `pytest`, `httpx`

### Frontend (Flutter)
- **Flutter SDK** (versión mínima `^3.11.3`).
- Los paquetes principales utilizados en `frontend/pubspec.yaml`:
  - `google_fonts` y `cupertino_icons` (diseño e iconografía)
  - `shared_preferences` (sesión local)
  - `http` (peticiones REST; la app usa `ApiClient` en `lib/core/network/api_client.dart` como capa común)
  - `app_settings` (ajustes del sistema en móvil)
- **Navegación:** la app usa `MaterialApp` + `Navigator` convencional (no `go_router`).

### Integración continua (CI)

El archivo `.github/workflows/ci.yml` ejecuta en cada push y pull request hacia `main`:

- **Backend:** instalación de dependencias y `pytest tests/`
- **Frontend:** `flutter pub get` y `flutter test`

---

## 🚀 Cómo ejecutar el proyecto en modo local

Para inicializar completamente el entorno de desarrollo, necesitas levantar tanto el backend como el frontend en **terminales separadas**.

### 1. Iniciar el Backend
1. Abre una terminal en la raíz del proyecto y dirígete a la carpeta del backend.
   ```bash
   cd backend
   ```
2. Activa tu entorno virtual asociado (ejemplo en Mac/Linux):
   ```bash
   source venv/bin/activate
   ```
3. *(Opcional)* Si es la primera vez que configuras la base de datos, ejecuta el archivo semilla para insertar al usuario administrador (admin):
   ```bash
   python seed.py
   ```
4. Levanta el servidor con Uvicorn:
   ```bash
   uvicorn main:app --reload
   ```
   El backend estará escuchando peticiones y operando correctamente en `http://localhost:8000`.

### 2. Iniciar el Frontend
Manten tu primera terminal abierta (con el backend ya corriendo) y abre una **nueva ventana o pestaña** de terminal:

1. Dirígete a la carpeta contenedora del frontend.
   ```bash
   cd frontend
   ```
2. Obtén e instala todas las dependencias y librerías del proyecto de Flutter:
   ```bash
   flutter pub get
   ```
3. Compila y ejecuta la aplicación (selecciona tu emulador, navegador o dispositivo conectado):
   ```bash
   flutter run
   ```

