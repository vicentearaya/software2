#!/usr/bin/env bash
# Fuerza la parada de contenedores CleanPool cuando "docker stop" falla con
# "permission denied" por conflicto AppArmor entre Docker Snap y Docker apt.
#
# Uso: sudo bash scripts/force-stop-stack.sh

set -euo pipefail

if [[ "${EUID:-}" -ne 0 ]]; then
  echo "Ejecuta con sudo: sudo bash $0"
  exit 1
fi

cd "$(dirname "$0")/.."

echo "==> Relajando perfiles AppArmor de Docker (temporal)..."
for profile in docker-default snap.docker.dockerd snap.docker.docker; do
  if aa-status 2>/dev/null | grep -q "$profile"; then
    aa-complain "$profile" 2>/dev/null || true
  fi
done

echo "==> Deteniendo contenedores CleanPool..."
NAMES=(cleanpool_frontend cleanpool_backend cleanpool_mongo cleanpool_mosquitto)
for name in "${NAMES[@]}"; do
  if ! docker inspect "$name" &>/dev/null; then
    continue
  fi
  pid="$(docker inspect -f '{{.State.Pid}}' "$name" 2>/dev/null || echo 0)"
  if [[ -n "$pid" && "$pid" != "0" ]]; then
    kill -9 "$pid" 2>/dev/null || true
  fi
  docker rm -f "$name" 2>/dev/null || true
  echo "  eliminado: $name"
done

echo "==> docker compose down -v..."
docker compose down -v 2>/dev/null || true

echo "OK. Ahora levanta el stack: sudo docker compose up -d --build"
