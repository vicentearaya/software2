#!/usr/bin/env bash
# Levanta o actualiza el stack CleanPool (desde la raíz del repo).
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "Falta .env — copia desde .env.example: cp .env.example .env"
  exit 1
fi

docker compose up -d --build "$@"

echo ""
docker compose ps
echo ""
echo "API:      http://${DOMAIN:-localhost}:8883/docs"
echo "Frontend: http://${DOMAIN:-localhost}:8884"
echo "MongoDB:  ${DOMAIN:-localhost}:8885"
echo "MQTT:     ${DOMAIN:-localhost}:1883"
