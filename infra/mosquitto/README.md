# Mosquitto (puerto 1883)

Broker MQTT en Docker (`cleanpool_mosquitto`).

- Usuario: `cleanpool` (variable `MQTT_USER` en `.env`)
- Contraseña: misma que `API_KEY` del backend
- El archivo `passwd` es un hash generado con `mosquitto_passwd`
- Debe ser legible por el usuario `mosquitto` del contenedor: `chmod 644 passwd`

Regenerar contraseña si cambias `API_KEY`:

```bash
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$PWD/infra/mosquitto:/out" eclipse-mosquitto:2 \
  mosquitto_passwd -b -c /out/passwd cleanpool 'nueva_api_key'
docker compose restart mosquitto
```

Topics sugeridos: `cleanpool/{pool_id}/lectura`, `cleanpool/{pool_id}/temperatura`.

El backend (FastAPI) se suscribe a `cleanpool/+/temperatura`, persiste en MongoDB y actualiza `last_seen_at` del vínculo activo. El slug del topic (ej. `piscina-1`) debe coincidir con `mqtt_topic_slug` al vincular el dispositivo en el Dashboard.
