# Levanta Mongo (Docker), crea backend/.env si no existe, arranca FastAPI y registra usuario demo.
# Uso (desde la raíz del repo):
#   powershell -ExecutionPolicy Bypass -File scripts/local-dev.ps1
#
# Credenciales para la app:
#   Usuario:    demo_local
#   Contraseña: DemoLocal2026!

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "==> Comprobando Docker..." -ForegroundColor Cyan
docker info *>$null
$dockerOk = ($LASTEXITCODE -eq 0)
if (-not $dockerOk) {
    Write-Host "ADVERTENCIA: Docker no está en ejecución o no responde." -ForegroundColor Red
    Write-Host "  Inicia Docker Desktop y ejecuta:  docker compose up -d mongo" -ForegroundColor Yellow
    Write-Host "  Mongo local escucha en el puerto 8885 (ver docker-compose.yml)." -ForegroundColor Yellow
} else {
    Write-Host "==> Iniciando Mongo (docker compose up -d mongo)..." -ForegroundColor Cyan
    docker compose up -d mongo
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR al levantar el contenedor mongo. Revisa docker compose." -ForegroundColor Red
    }
    Start-Sleep -Seconds 4
}

$envPath = Join-Path $root "backend\.env"
if (-not (Test-Path $envPath)) {
    $chars = [char[]]((48..57) + (65..90) + (97..122))
    $secret = -join (1..48 | ForEach-Object { $chars | Get-Random })
    @"
MONGODB_URI=mongodb://127.0.0.1:8885/cleanpool
SECRET_KEY=$secret
API_KEY=local-dev-esp-api-key-change-me
"@ | Set-Content -Path $envPath -Encoding UTF8
    Write-Host "==> Creado backend\.env (Mongo local puerto 8885)." -ForegroundColor Green
} else {
    Write-Host "==> backend\.env ya existe (no se modifica)." -ForegroundColor Yellow
    Write-Host "    Para Mongo Docker local: MONGODB_URI=mongodb://127.0.0.1:8885/cleanpool" -ForegroundColor DarkGray
}

$backend = Join-Path $root "backend"
Set-Location $backend
if (-not (Test-Path ".\venv\Scripts\Activate.ps1")) {
    Write-Host "==> Creando venv..." -ForegroundColor Cyan
    python -m venv venv
}
& .\venv\Scripts\Activate.ps1
Write-Host "==> pip install..." -ForegroundColor Cyan
pip install -q -r requirements.txt

Write-Host "==> Arrancando uvicorn en segundo plano (puerto 8000)..." -ForegroundColor Cyan
$uvicornCmd = "cd `"$backend`"; .\venv\Scripts\Activate.ps1; uvicorn main:app --host 0.0.0.0 --port 8000"
Start-Process powershell -ArgumentList "-NoExit", "-Command", $uvicornCmd -WindowStyle Normal

$health = $null
for ($i = 0; $i -lt 30; $i++) {
    try {
        $health = Invoke-WebRequest -Uri "http://127.0.0.1:8000/" -UseBasicParsing -TimeoutSec 2
        if ($health.StatusCode -eq 200) { break }
    } catch { Start-Sleep -Seconds 1 }
}
if (-not $health -or $health.StatusCode -ne 200) {
    Write-Host "ERROR: El API no respondió en http://127.0.0.1:8000/. Revisa la ventana de uvicorn." -ForegroundColor Red
    exit 1
}

Write-Host "==> Registrando usuario demo..." -ForegroundColor Cyan
$body = @{
    name     = "Usuario Demo Local"
    username = "demo_local"
    email    = "demo_local@cleanpool.local"
    password = "DemoLocal2026!"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "http://127.0.0.1:8000/auth/register" -Method Post -Body $body -ContentType "application/json" | Out-Null
    Write-Host "    Usuario demo_local creado." -ForegroundColor Green
} catch {
    $code = $null
    if ($_.Exception.Response) { $code = [int]$_.Exception.Response.StatusCode }
    if ($code -eq 400) {
        Write-Host "    demo_local ya existía (puedes iniciar sesión)." -ForegroundColor Yellow
    } else {
        Write-Host "    Register: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor White
Write-Host " LISTO — Usa estas credenciales en la app (login):" -ForegroundColor White
Write-Host "   Usuario:     demo_local"
Write-Host "   Contraseña:  DemoLocal2026!"
Write-Host "============================================================" -ForegroundColor White
Write-Host ""
Write-Host "API:     http://127.0.0.1:8000/docs" -ForegroundColor Cyan
Write-Host "Flutter (Chrome, API local):" -ForegroundColor Cyan
Write-Host "  cd `"$($root)\frontend`"; flutter pub get; flutter run -d chrome --dart-define=API_URL=http://localhost:8000"
Write-Host ""
Write-Host "Android emulador: --dart-define=API_URL=http://10.0.2.2:8000" -ForegroundColor DarkGray
Write-Host ""
