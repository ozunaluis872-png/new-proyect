param(
    [switch]$LaunchApp
)

$ErrorActionPreference = "Stop"

$rootPath = Split-Path -Parent $PSScriptRoot
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

if (-not (Test-Path $backendPath)) {
    Write-Host 'No se encontro la carpeta del backend.' -ForegroundColor Red
    exit 1
}

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Host '.NET no esta disponible en PATH.' -ForegroundColor Red
    exit 1
}

$localIp = Get-LocalIPv4Address
if ([string]::IsNullOrWhiteSpace($localIp)) {
    Write-Host 'No se pudo detectar una IP local. Usando localhost para desarrollo local.' -ForegroundColor Yellow
    $localIp = 'localhost'
} else {
    Write-Host "IP Local detectada: $localIp" -ForegroundColor Cyan
}

Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Iniciando Backend Loginova" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "El backend estara disponible en: http://$localIp:5105" -ForegroundColor Green
Write-Host ""
Write-Host "Desde tu celular conecta a: http://$localIp:5105/api" -ForegroundColor Green
Write-Host ""
Write-Host "Presiona Ctrl+C para detener el backend." -ForegroundColor Yellow
Write-Host ""
Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Set-Location $backendPath
& dotnet run --urls "$backendUrl"
