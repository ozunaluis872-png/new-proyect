param(
    [string]$ApiBaseUrl = "",
    [switch]$Install,
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

$rootPath = Split-Path -Parent $PSScriptRoot
$frontendPath = Join-Path $rootPath 'Loginova'
$backendPath = Join-Path $rootPath 'LoginovaBackend\LoginovaAPI'
$backendUrl = 'http://0.0.0.0:5105'

function Get-LocalIPv4Address {
    if (-not (Get-Command Get-NetIPAddress -ErrorAction SilentlyContinue)) {
        return $null
    }

    $candidate = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -ne '127.0.0.1' -and
            $_.IPAddress -notlike '169.254*' -and
            $_.InterfaceOperationalStatus -eq 'Up'
        } |
        Select-Object -First 1

    if ($null -eq $candidate) {
        return $null
    }

    return $candidate.IPAddress
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $localIp = Get-LocalIPv4Address
    if ([string]::IsNullOrWhiteSpace($localIp)) {
        $ApiBaseUrl = 'http://localhost:5105/api'
        Write-Host 'No se pudo detectar una IP local; se usara localhost para compilar.' -ForegroundColor Yellow
        Write-Host 'Para usar un celular fisico, vuelve a ejecutar pasando -ApiBaseUrl con la IP de tu PC.' -ForegroundColor Yellow
    } else {
        $ApiBaseUrl = "http://$localIp:5105/api"
        Write-Host "API_BASE_URL detectada automaticamente: $ApiBaseUrl" -ForegroundColor Cyan
    }
}

if (-not (Test-Path $frontendPath) -or -not (Test-Path $backendPath)) {
    Write-Host 'No se encontraron las carpetas del frontend o backend.' -ForegroundColor Red
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host 'Flutter no esta disponible en PATH.' -ForegroundColor Red
    exit 1
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host '.NET no esta disponible en PATH.' -ForegroundColor Red
    exit 1
}

Write-Host 'Iniciando backend en modo desarrollo para uso en red local...' -ForegroundColor Cyan
Start-Process -FilePath 'powershell' -WorkingDirectory $backendPath -ArgumentList @(
    '-NoExit',
    '-Command',
    "dotnet run --urls `"$backendUrl`""
)

Write-Host 'Esperando a que el backend responda...' -ForegroundColor Yellow
$ready = $false
for ($i = 0; $i -lt 60; $i++) {
    try {
        Invoke-WebRequest -Uri 'http://127.0.0.1:5105/openapi/v1.json' -UseBasicParsing | Out-Null
        $ready = $true
        break
    } catch {
        Start-Sleep -Seconds 1
    }
}

if (-not $ready) {
    Write-Host 'El backend no respondio a tiempo. Verifica que no haya un bloqueo de puertos o firewall.' -ForegroundColor Red
    exit 1
}

Write-Host 'Backend listo. Construyendo APK...' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'build-apk.ps1') -ApiBaseUrl $ApiBaseUrl -Install:$Install -DeviceId $DeviceId