#!/usr/bin/env bash
# Instala limpieza automática semanal de disco Docker (cron del servidor).
set -euo pipefail

cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"
CRON_LINE="0 3 * * 0 cd ${REPO_ROOT} && /usr/bin/bash scripts/docker-disk-maintenance.sh >> /var/log/cleanpool-docker-maintenance.log 2>&1"

if [[ "${EUID:-}" -ne 0 ]]; then
  exec sudo bash "$0"
fi

chmod +x scripts/docker-disk-maintenance.sh

TMP_CRON="$(mktemp)"
crontab -u alumno -l 2>/dev/null | grep -v 'docker-disk-maintenance.sh' >"$TMP_CRON" || true
echo "$CRON_LINE" >>"$TMP_CRON"
crontab -u alumno "$TMP_CRON"
rm -f "$TMP_CRON"

touch /var/log/cleanpool-docker-maintenance.log
chown alumno:alumno /var/log/cleanpool-docker-maintenance.log

echo "Cron instalado para usuario alumno:"
crontab -u alumno -l | grep docker-disk-maintenance.sh
echo "Log: /var/log/cleanpool-docker-maintenance.log"
