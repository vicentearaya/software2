#!/usr/bin/env bash
# Mantenimiento seguro del servidor para evitar disco lleno en autodeploys.
# Instalar: sudo bash scripts/install-cleanpool-server-maintenance.sh
#
# Uso manual:
#   sudo /usr/local/bin/cleanpool-server-maintenance
#
# Antes de un deploy importante:
#   sudo AGGRESSIVE=1 /usr/local/bin/cleanpool-server-maintenance

set -euo pipefail

AGGRESSIVE="${AGGRESSIVE:-0}"
MIN_FREE_GB="${MIN_FREE_GB:-5}"
THRESHOLD_PERCENT="${THRESHOLD_PERCENT:-85}"

log() {
  echo "[cleanpool-server-maintenance] $*"
}

disk_use_percent() {
  df / | awk 'NR==2 {gsub(/%/, "", $5); print $5}'
}

disk_free_gb() {
  df / | awk 'NR==2 {printf "%.0f", $4/1024/1024}'
}

docker_cmd() {
  docker "$@"
}

USE_BEFORE="$(disk_use_percent)"
FREE_BEFORE="$(disk_free_gb)"
log "Disco / al ${USE_BEFORE}% (${FREE_BEFORE}G libres) antes de limpiar"

log "Limpiando logs del journal"
journalctl --vacuum-size=100M >/dev/null 2>&1 || true

log "Truncando logs de contenedores Docker"
find /var/lib/docker/containers -name "*-json.log" -exec truncate -s 0 {} \; 2>/dev/null || true

log "Eliminando contenedores detenidos de Dokploy/CleanPool"
while IFS= read -r id; do
  [[ -z "$id" ]] && continue
  docker_cmd rm -f "$id" >/dev/null 2>&1 || true
done < <(docker_cmd ps -aq --filter "status=exited" 2>/dev/null || true)

if [[ "$AGGRESSIVE" == "1" || "$USE_BEFORE" -ge "$THRESHOLD_PERCENT" ]]; then
  log "Limpiando build cache completa"
  docker_cmd builder prune -af >/dev/null 2>&1 || true
else
  log "Limpiando build cache antigua (>24h)"
  docker_cmd builder prune -af --filter "until=24h" >/dev/null 2>&1 \
    || docker_cmd builder prune -f >/dev/null 2>&1 || true
fi

log "Eliminando imágenes dangling"
docker_cmd image prune -f >/dev/null 2>&1 || true

log "Eliminando volúmenes huérfanos"
docker_cmd volume prune -f >/dev/null 2>&1 || true

for vol in software2_mongo_data software2_mosquitto_data software2_mosquitto_log; do
  links="$(docker_cmd volume ls --filter "name=^${vol}$" --format '{{.Links}}' 2>/dev/null || echo 1)"
  if [[ "$links" == "0" ]]; then
    log "Eliminando volumen huérfano $vol"
    docker_cmd volume rm "$vol" >/dev/null 2>&1 || true
  fi
done

apt-get clean >/dev/null 2>&1 || true

USE_AFTER="$(disk_use_percent)"
FREE_AFTER="$(disk_free_gb)"
log "Disco / al ${USE_AFTER}% (${FREE_AFTER}G libres) después de limpiar"
docker_cmd system df 2>/dev/null || true

if [[ "$FREE_AFTER" -lt "$MIN_FREE_GB" && "$AGGRESSIVE" == "1" ]]; then
  log "AVISO: menos de ${MIN_FREE_GB}G libres. Ejecuta deploy solo si es urgente."
  exit 1
fi
