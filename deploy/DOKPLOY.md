# Despliegue con Dokploy (rama `main`)

Dokploy corre en el puerto **8886** y no forma parte de este `docker-compose.yml`.

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

## MQTT de prueba

```bash
mosquitto_sub -h 127.0.0.1 -p 1883 -u cleanpool -P "$API_KEY" -t 'cleanpool/#' -v
mosquitto_pub -h 127.0.0.1 -p 1883 -u cleanpool -P "$API_KEY" \
  -t cleanpool/piscina-1/lectura -m '{"ph":7.2,"cloro":1.5,"temperatura":26,"conductividad":800}'
```

Instalar clientes en el host si hace falta: `sudo apt install mosquitto-clients`
