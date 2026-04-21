FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

# Pasamos la URL del backend por argumento de build
ARG API_URL=""

RUN flutter config --enable-web
RUN flutter pub get

# Compilar para entorno web inyectando la URL de la API
RUN flutter build web --dart-define=API_URL=$API_URL

FROM nginx:alpine
# Copiar configuración adaptada para SPA de Flutter
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copiar archivos compilados al servidor estático
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
