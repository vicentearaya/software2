FROM python:3.10-slim

WORKDIR /app

# Copiar requirements de producción e instalarlas
COPY requirements-prod.txt .
RUN pip install --no-cache-dir --prefer-binary -r requirements-prod.txt

# Copiar el código fuente
COPY . .

# Exponer el puerto
EXPOSE 8000

# Comando para arrancar el servidor
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
