# Despliegue en producción (rama `main`)

Usa **solo Dokploy** para auto-deploy en `main` (desactiva el workflow de GitHub Actions si no quieres dos despliegues a la vez).

| Método | Archivo / herramienta |
|--------|------------------------|
| **Producción** | Dokploy en puerto **8886** (webhook / auto-deploy desde Git) |
| Manual / emergencia | SSH + `docker compose` en `/home/alumno/software2` |

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
7. **Una vez en el servidor** (permite pre-deploy sin contraseña y evita `permission denied` al redeploy):
   ```bash
   cd ~/software2 && git pull origin main
   sudo cp scripts/cleanpool-kill-stack.sh /usr/local/bin/cleanpool-kill-stack
   sudo chmod +x /usr/local/bin/cleanpool-kill-stack
   echo 'alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-kill-stack' | sudo tee /etc/sudoers.d/cleanpool-dokploy
   sudo chmod 440 /etc/sudoers.d/cleanpool-dokploy
   ```
8. En **Advanced** → **Pre Deploy Command** (obligatorio en este servidor):
   ```bash
   sudo /usr/local/bin/cleanpool-kill-stack
   ```
   Sin esto, cada redeploy puede fallar con `cannot stop container: permission denied`.
9. Primer deploy: **Deploy** (ver abajo si ya hay contenedores levantados)

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

## Error: `container name "/cleanpool_..." is already in use`

El `docker-compose.yml` usa nombres fijos (`container_name: cleanpool_mongo`, etc.). Si el stack ya está **Up** por un deploy manual, Dokploy no puede crear otros con el mismo nombre.

**Ahora (una vez):** en el servidor por SSH (no uses solo `docker rm`; falla con *permission denied*):

```bash
cd ~/software2
sudo KEEP_VOLUMES=1 bash scripts/force-stop-stack.sh
```

Luego en Dokploy pulsa **Deploy** otra vez.

Si aún falla: `sudo systemctl restart docker` y repite el script.

**Para siempre:** configura el Pre Deploy Command de arriba (`scripts/dokploy-pre-deploy.sh`).

Importante: el cambio del README debe estar en **GitHub** (`git push origin main`). Dokploy despliega desde el remoto, no desde tu PC local.

## Error: `Bind for 0.0.0.0:8884 failed: port is already allocated`

Quedó un contenedor **viejo de Dokploy** usando el puerto (nombre tipo `7c11c7b03fad_cleanpool_frontend`).

```bash
cd ~/software2
sudo bash scripts/force-stop-stack.sh
sudo docker compose up -d --build
```

## Error: `cannot stop container: permission denied` (redeploy Dokploy)

Dokploy ejecuta `docker stop` y AppArmor/Snap lo bloquea. **`docker rm` o `compose down` sin `kill -9` no sirven.**

**Ahora (SSH):**

```bash
sudo /usr/local/bin/cleanpool-kill-stack
```

Si no lo instalaste aún:

```bash
cd ~/software2
sudo bash scripts/cleanpool-kill-stack.sh
```

Luego en Dokploy: **Deploy** otra vez.

**Para que no vuelva:** instala `cleanpool-kill-stack` y configura el Pre Deploy Command (pasos 7–8 arriba).

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
