FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Pasamos la URL del backend por argumento de build
ARG API_URL=""

# Copiamos primero los archivos de dependencias para aprovechar caché y
# evitar invalidar `flutter pub get` en cada cambio de código.
COPY pubspec.yaml pubspec.lock ./

# Resolvemos dependencias antes de copiar el código fuente completo para
# reutilizar la caché cuando cambian solo archivos de la app.
RUN flutter config --enable-web && flutter pub get

COPY . .

# Compilar para entorno web inyectando la URL de la API y luego limpiar la
# caché descargada para reducir el espacio retenido por el builder.
RUN flutter build web --dart-define=API_URL=$API_URL \
    && rm -rf /root/.pub-cache

FROM nginx:alpine
# Copiar configuración adaptada para SPA de Flutter
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar archivos compilados al servidor estático
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
