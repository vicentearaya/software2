#!/usr/bin/env bash
# Ejecutar en el servidor ANTES de pulsar Deploy en Dokploy.
# Instalar: sudo bash scripts/install-cleanpool-server-maintenance.sh
set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Requiere root: sudo /usr/local/bin/cleanpool-pre-deploy" >&2
  exit 1
fi

AGGRESSIVE=1 /usr/local/bin/cleanpool-server-maintenance

if [[ "${FULL_STACK:-0}" == "1" ]]; then
  /usr/local/bin/cleanpool-kill-stack
else
  /usr/local/bin/cleanpool-kill-app
fi

echo "cleanpool-pre-deploy: listo para Deploy en Dokploy"
