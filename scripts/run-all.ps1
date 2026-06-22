# Script para ejecutar Frontend y Backend simultaneamente
# Uso: .\scripts\run-all.ps1

param(
    [switch]$WithSmoke
)

$rootPath = Split-Path -Parent $PSScriptRoot
$frontendPath = Join-Path $rootPath 'Loginova'
$backendPath = Join-Path $rootPath 'LoginovaBackend\LoginovaAPI'

Write-Host 'Iniciando Loginova (Frontend + Backend)'

if (-not (Test-Path $frontendPath) -or -not (Test-Path $backendPath)) {
    Write-Host 'Error: ejecuta este script desde la raiz del workspace new proyect'
    exit 1
}

Set-Location $rootPath

Write-Host '1/3 Restaurando dependencias del backend'
Push-Location $backendPath
dotnet restore
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host 'Error al restaurar dependencias del backend'
    exit 1
}
Pop-Location

Write-Host '2/3 Restaurando dependencias del frontend'
Push-Location $frontendPath
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host 'Error al restaurar dependencias del frontend'
    exit 1
}
Pop-Location

Write-Host '3/3 Iniciando servicios en ventanas separadas'

Start-Process -FilePath 'powershell' -WorkingDirectory $backendPath -ArgumentList '-NoExit', '-Command', 'dotnet run'
Start-Process -FilePath 'powershell' -WorkingDirectory $frontendPath -ArgumentList '-NoExit', '-Command', 'flutter run'

Write-Host 'Ambos servicios iniciados'
Write-Host 'Backend: http://localhost:5105'
Write-Host 'Frontend: Flutter en emulador o dispositivo'
Write-Host 'Para detenerlos, cierra las dos ventanas de PowerShell o usa Ctrl+C en cada una.'

if ($WithSmoke) {
    Write-Host 'Esperando backend para ejecutar smoke test...'

    $ready = $false
    for ($i = 0; $i -lt 20; $i++) {
        try {
            Invoke-WebRequest -Uri 'http://localhost:5105/api/auth/login' -Method Post -ContentType 'application/json' -Body '{"correo":"admin@loginova.com","password":"admin123"}' -UseBasicParsing | Out-Null
            $ready = $true
            break
        } catch {
            Start-Sleep -Seconds 1
        }
    }

    if (-not $ready) {
        Write-Host 'No se pudo validar que el backend estuviera listo para smoke test.'
        exit 1
    }

    Write-Host 'Ejecutando smoke test API...'
    & (Join-Path $rootPath 'scripts\smoke-api.ps1')
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Smoke test fallo.'
        exit 1
    }

    Write-Host 'Smoke test completado correctamente.'
}
