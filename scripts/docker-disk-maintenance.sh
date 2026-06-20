#!/usr/bin/env bash
# Limpieza segura de disco Docker en el servidor (sin borrar datos de producción).
#
# Uso manual:
#   sudo bash scripts/docker-disk-maintenance.sh
#
# Modo agresivo (antes de un deploy con poco espacio):
#   sudo AGGRESSIVE=1 bash scripts/docker-disk-maintenance.sh
#
# No borra volúmenes en uso (mongo, mosquitto, dokploy).

set -euo pipefail

AGGRESSIVE="${AGGRESSIVE:-0}"
THRESHOLD_PERCENT="${THRESHOLD_PERCENT:-85}"

log() {
  echo "[docker-disk-maintenance] $*"
}

disk_use_percent() {
  df / | awk 'NR==2 {gsub(/%/, "", $5); print $5}'
}

docker_cmd() {
  if docker info >/dev/null 2>&1; then
    docker "$@"
  else
    sudo docker "$@"
  fi
}

USE_BEFORE="$(disk_use_percent)"
log "Disco / al ${USE_BEFORE}% antes de limpiar"

if [[ "$AGGRESSIVE" == "1" || "$USE_BEFORE" -ge "$THRESHOLD_PERCENT" ]]; then
  log "Limpiando build cache completa (modo seguro para redeploys)"
  docker_cmd builder prune -af
else
  log "Limpiando build cache antigua (>48h)"
  docker_cmd builder prune -af --filter "until=48h" || docker_cmd builder prune -f
fi

log "Eliminando imágenes dangling (capas huérfanas)"
docker_cmd image prune -f

USE_AFTER="$(disk_use_percent)"
if [[ "$AGGRESSIVE" == "1" || "$USE_AFTER" -ge 92 ]]; then
  log "Disco aún al ${USE_AFTER}% — eliminando solo volúmenes huérfanos"
  docker_cmd volume prune -f
fi

log "Estado final:"
df -h /
docker_cmd system df
