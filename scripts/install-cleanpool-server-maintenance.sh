#!/usr/bin/env bash
# Instala mantenimiento automático en el servidor (una vez).
# Uso en el servidor:
#   cd ~/software2 && git pull origin main
#   sudo bash scripts/install-cleanpool-server-maintenance.sh
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ "${EUID:-}" -ne 0 ]]; then
  exec sudo bash "$0"
fi

install -m 755 scripts/cleanpool-server-maintenance.sh /usr/local/bin/cleanpool-server-maintenance
install -m 755 scripts/cleanpool-pre-deploy.sh /usr/local/bin/cleanpool-pre-deploy
install -m 755 scripts/cleanpool-kill-app.sh /usr/local/bin/cleanpool-kill-app

if [[ -x scripts/cleanpool-kill-stack.sh ]]; then
  install -m 755 scripts/cleanpool-kill-stack.sh /usr/local/bin/cleanpool-kill-stack
fi

SUDOERS_FILE=/etc/sudoers.d/cleanpool-dokploy
cat >"$SUDOERS_FILE" <<'EOF'
alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-kill-stack
alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-kill-app
alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-pre-deploy
alumno ALL=(ALL) NOPASSWD: /usr/local/bin/cleanpool-server-maintenance
EOF
chmod 440 "$SUDOERS_FILE"

touch /var/log/cleanpool-server-maintenance.log
chown alumno:alumno /var/log/cleanpool-server-maintenance.log

CRON_MAINT='0 */4 * * * /usr/local/bin/cleanpool-server-maintenance >> /var/log/cleanpool-server-maintenance.log 2>&1'
CRON_DEEP='0 3 * * 0 AGGRESSIVE=1 /usr/local/bin/cleanpool-server-maintenance >> /var/log/cleanpool-server-maintenance.log 2>&1'

TMP_CRON="$(mktemp)"
crontab -u alumno -l 2>/dev/null \
  | grep -v 'cleanpool-server-maintenance' \
  | grep -v 'docker-disk-maintenance' \
  >"$TMP_CRON" || true
echo "$CRON_MAINT" >>"$TMP_CRON"
echo "$CRON_DEEP" >>"$TMP_CRON"
crontab -u alumno "$TMP_CRON"
rm -f "$TMP_CRON"

echo "Instalado:"
echo "  /usr/local/bin/cleanpool-server-maintenance"
echo "  /usr/local/bin/cleanpool-pre-deploy"
echo "  /usr/local/bin/cleanpool-kill-app"
echo "Cron (cada 4h + domingo 03:00):"
crontab -u alumno -l | grep cleanpool-server-maintenance
echo "Log: /var/log/cleanpool-server-maintenance.log"
