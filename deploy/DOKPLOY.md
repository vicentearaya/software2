# Despliegue en producción (rama `main`)

Elige **una** estrategia de auto-deploy (no uses las dos a la vez o desplegarás dos veces):

| Método | Archivo / herramienta |
|--------|------------------------|
| **Recomendado (este repo)** | GitHub Actions → `.github/workflows/deploy.yml` (SSH + `git pull` + `docker compose`) |
| Alternativa | Dokploy en puerto **8886** (webhook / auto-deploy desde Git) |

Dokploy corre en el puerto **8886** y no forma parte de este `docker-compose.yml`.

## GitHub Actions (SSH)

1. En GitHub: **Settings → Secrets and variables → Actions → New repository secret**
   - `SERVER_HOST` = IP del servidor (ej. `200.27.101.243`)
   - `SERVER_USER` = `alumno`
   - `SERVER_SSH_KEY` = clave privada SSH que pueda entrar al servidor (sin passphrase, o usa `key` + agent)
   - `SERVER_SSH_PORT` = `22` (opcional)
2. En el servidor, el repo debe existir en `/home/alumno/software2` y el usuario SSH debe poder ejecutar `git pull` y `docker compose` (grupo `docker`).
3. Cada **push a `main`** ejecuta CI (`.github/workflows/ci.yml`) y este deploy en paralelo.

Si `docker compose` falla con *permission denied*, en el servidor unifica Docker (ver sección de error más abajo) o cambia el script del workflow a `sudo docker compose` (requiere NOPASSWD en sudoers).

## Mapa de puertos

| Puerto | Servicio |
|--------|----------|
| 1883 | Mosquitto (MQTT) |
| 8883 | Backend FastAPI |
| 8884 | Frontend (nginx) |
| 8885 | MongoDB (app + logs) |
| 8886 | Dokploy (panel) |

## Crear la aplicación en Dokploy

1. Abre Dokploy: `http://<IP_SERVIDOR>:8886`
2. **New Project** → tipo **Docker Compose**
3. Conecta el repositorio GitHub `vicentearaya/software2`
4. Configuración:
   - **Branch:** `main` (auto-deploy en cada push a `main`)
   - **Compose path:** `docker-compose.yml`
   - **Root path:** `/` (raíz del repo)
5. Variables de entorno (pestaña Environment): mismas que en `.env.example`
   - `DOMAIN`, `SECRET_KEY`, `API_KEY`, `API_URL`, `MQTT_USER`
6. Activa **Auto Deploy** / webhook de Git si está disponible en tu versión de Dokploy
7. Primer deploy: **Deploy**

## Flujo recomendado de ramas

1. Desarrollo en ramas feature (ej. `mosquitto`) → PR a `develop`
2. Cuando esté estable, merge `develop` → `main`
3. Push a `main` → Dokploy reconstruye y levanta el stack

## Primera puesta en marcha (BD vacía)

Si quieres MongoDB desde cero (sin datos de Atlas):

```bash
cd ~/software2
docker compose down -v
docker compose up -d --build
docker compose exec backend python seed.py
```

`seed.py` crea el usuario admin y datos de ejemplo en la BD local.

## Error: `cannot stop container: permission denied`

En Ubuntu suele haber **dos Docker** (Snap + apt) y AppArmor bloquea las señales entre ellos.

Solución en el servidor:

```bash
cd ~/software2
sudo bash scripts/force-stop-stack.sh
sudo docker compose up -d --build
```

A largo plazo, deja **solo un** Docker (recomendado: apt, desactivar Snap):

```bash
sudo snap stop docker
sudo snap disable docker
sudo systemctl enable --now docker
```

## Comandos útiles en el servidor

```bash
docker compose ps
docker compose logs -f backend
docker compose logs -f mosquitto
```

## Presencia del ESP8266

El backend suscribe `cleanpool/+/temperatura`, guarda lecturas en MongoDB y marca el dispositivo **ONLINE** si hubo lectura en los últimos **2 minutos**.

Al vincular desde el Dashboard se envía `mqtt_topic_slug: piscina-1` (debe coincidir con `POOL_ID` del firmware).

Tras desplegar, **re-vincula** el dispositivo una vez si el vínculo es anterior a este cambio.

## MQTT de prueba

```bash
mosquitto_sub -h 127.0.0.1 -p 1883 -u cleanpool -P "$API_KEY" -t 'cleanpool/#' -v
mosquitto_pub -h 127.0.0.1 -p 1883 -u cleanpool -P "$API_KEY" \
  -t cleanpool/piscina-1/lectura -m '{"ph":7.2,"cloro":1.5,"temperatura":26,"conductividad":800}'
```

Instalar clientes en el host si hace falta: `sudo apt install mosquitto-clients`
