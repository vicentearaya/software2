#!/usr/bin/env bash
# Fuerza la parada de contenedores CleanPool cuando "docker stop/rm" falla con
# "permission denied" (conflicto AppArmor / Docker Snap + apt).
#
# Uso:
#   sudo bash scripts/force-stop-stack.sh          # baja stack y borra volúmenes
#   sudo KEEP_VOLUMES=1 bash scripts/force-stop-stack.sh   # conserva Mongo

set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo bash $0"
  exit 1
fi

cd "$(dirname "$0")/.."
SCRIPT_DIR="$(dirname "$0")"

# shellcheck source=lib/force-remove-cleanpool.sh
source "$SCRIPT_DIR/lib/force-remove-cleanpool.sh"
force_remove_cleanpool_containers

if [[ "${KEEP_VOLUMES:-}" == "1" ]]; then
  echo "==> docker compose down (sin -v, conservando volúmenes)..."
  docker compose down --remove-orphans 2>/dev/null || true
else
  echo "==> docker compose down -v..."
  docker compose down -v 2>/dev/null || true
fi

echo "OK. Siguiente paso: Deploy en Dokploy, o: sudo docker compose up -d --build"
