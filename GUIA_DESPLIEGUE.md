# Guía de Dockerización y Despliegue en Dokploy

Este documento contiene las instrucciones para el equipo de desarrollo sobre cómo utilizar el entorno de Docker localmente (`develop`), y también las instrucciones para administrar el servidor de producción Dokploy.

## Para el Equipo de Desarrollo (Entorno Local)

Si eres miembro del equipo y estás trabajando en la rama `develop`, ya no es necesario configurar Flutter y Python de forma nativa a menos que quieras compilar específicamente para móvil. 
Puedes correr toda la arquitectura (Base de Datos remota + Backend local + Frontend web local) con Docker:

1. Asegúrate de tener **Docker Desktop** instalado y abierto.
2. Abre la terminal en la raíz de este proyecto y ejecuta:
   ```bash
   docker compose up --build
   ```
3. El frontend de la aplicación web estará disponible en: [http://localhost:80](http://localhost:80)
4. El backend estará disponible y escuchando peticiones en: [http://localhost:8000](http://localhost:8000)

*(Si añades nuevas dependencias al `pubspec.yaml` del frontend o al `requirements.txt` del backend, vuelve a correr el comando anterior para reconstruir las imágenes).*

---

## Configuración Inicial del Servidor (Administrador)

Si es la primera vez que se monta el servidor universitario (`10.51.0.25`), o necesitas reinstalar la infraestructura, sigue estos pasos:

### 1. Conexión SSH al Servidor Ubuntu
Primero, conéctate a la VPN de la universidad usando *FortiClient*.
Abre una terminal (Git Bash, Putty, WSL o Terminal clásica) y accede por SSH:

```bash
ssh alumno@10.51.0.25
```
*(Ingresa la contraseña cuando se te solicite)*

### 2. Instalar Dokploy (Motor de despliegue)
Usa el siguiente script oficial para instalar Docker (si no lo tiene) y levantar Dokploy:
```bash
curl -sSL https://dokploy.com/install.sh | sh
```
Al finalizar, ve a tu navegador web e ingresa a `http://10.51.0.25:3000`. Te pedirá crear una cuenta de administrador. 

### 3. Configurar el Auto-Deploy en Dokploy
Una vez dentro del dashboard web de Dokploy:

1. Entra a "Projects" y crea uno llamado **CleanPool** (o el nombre que elijas).
2. Dentro del proyecto, pulsa el botón **Create Compose**.
3. En la sección *Source*, elige la opción **Git** o **GitHub** y conecta tu repositorio dando permisos (o ingresando la URL pública si la tienes).
4. Elige tu repositorio y selecciona la rama **`main`**.
5. En donde dice *Compose Path* verifica que diga `./docker-compose.yml`.
6. Haz clic en **Deploy**. 

Dokploy clonará el repositorio, construirá los contenedores de Frontend y Backend y los pondrá a funcionar.

### 4. Automatizar despliegues al hacer Push / Merge a `main`
Para que cada cambio en `main` se asimile automáticamente sin tener que entrar a Dokploy:

1. En tu aplicación "Compose" dentro de Dokploy, ve a la pestaña **Deploy**.
2. Abajo verás la sección **VCS / Trigger** (Webhook). Cópialo.
3. Ve a tu repositorio en GitHub $\rightarrow$ **Settings** $\rightarrow$ **Webhooks** $\rightarrow$ **Add webhook**.
4. Pega la URL en *Payload URL*. Tipo de contenido `application/json` o el que indique Dokploy.
5. Selecciona el evento `Just the push event`.

¡Con eso estarás listo! Todo empuje (*push*) a la rama de producción (`main`) actualizará tu aplicación completa.
