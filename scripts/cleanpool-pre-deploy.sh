#!/usr/bin/env bash
# Pre-deploy en el host: mata contenedores viejos y libera disco Docker.
# Instalar: sudo bash scripts/install-cleanpool-pre-deploy.sh
set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Requiere root: sudo /usr/local/bin/cleanpool-pre-deploy" >&2
  exit 1
fi

echo "==> cleanpool-pre-deploy: kill-stack"
/usr/local/bin/cleanpool-kill-stack

echo "==> cleanpool-pre-deploy: limpieza de disco Docker"
docker builder prune -af
docker image prune -f

USE="$(df / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')"
if [[ "$USE" -ge 92 ]]; then
  echo "==> Disco al ${USE}%: volúmenes huérfanos"
  docker volume prune -f
fi

echo "==> Estado de disco:"
df -h /
docker system df
