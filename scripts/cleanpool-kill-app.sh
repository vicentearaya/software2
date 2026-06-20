#!/usr/bin/env bash
# Detiene solo backend/frontend antes de redeploy (deja Mongo y Mosquitto corriendo).
# Instalar: sudo bash scripts/install-cleanpool-server-maintenance.sh
set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Requiere root: sudo /usr/local/bin/cleanpool-kill-app" >&2
  exit 1
fi

for name in cleanpool_backend cleanpool_frontend; do
  if docker ps -a --format '{{.Names}}' | grep -qx "$name"; then
    pid="$(docker inspect -f '{{.State.Pid}}' "$name" 2>/dev/null || echo 0)"
    if [[ -n "$pid" && "$pid" != "0" ]]; then
      kill -9 "$pid" 2>/dev/null || true
      sleep 0.2
    fi
    docker rm -f "$name" >/dev/null 2>&1 && echo "  eliminado: $name" || true
  fi
done

echo "cleanpool-kill-app: listo (mongo/mosquitto intactos)"
