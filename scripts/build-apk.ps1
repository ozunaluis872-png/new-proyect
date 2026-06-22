param(
    [string]$ApiBaseUrl = "",
    [switch]$Install,
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"

$rootPath = Split-Path -Parent $PSScriptRoot
$frontendPath = Join-Path $rootPath 'Loginova'
$apkPath = Join-Path $frontendPath 'build\app\outputs\flutter-apk\app-release.apk'

Write-Host 'Generando APK de Loginova' -ForegroundColor Cyan

if (-not (Test-Path $frontendPath)) {
    Write-Host 'No se encontro el proyecto Flutter en Loginova.' -ForegroundColor Red
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host 'Flutter no esta disponible en PATH.' -ForegroundColor Red
    exit 1
}

Set-Location $frontendPath

Write-Host '1/3 Restaurando dependencias de Flutter...' -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Error al restaurar dependencias de Flutter.' -ForegroundColor Red
    exit 1
}

$buildArgs = @('build', 'apk', '--release')

if (-not [string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $buildArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"
    Write-Host "Usando API_BASE_URL=$ApiBaseUrl" -ForegroundColor Cyan
} else {
    Write-Host 'No se paso API_BASE_URL. En un celular fisico, el APK intentara usar la URL por defecto de la app.' -ForegroundColor Yellow
}

Write-Host '2/3 Compilando APK...' -ForegroundColor Yellow
& flutter @buildArgs
if ($LASTEXITCODE -ne 0) {
    Write-Host 'Error al compilar el APK.' -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $apkPath)) {
    Write-Host "No se encontro el APK generado en $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host "APK generado en: $apkPath" -ForegroundColor Green

if ($Install) {
    Write-Host '3/3 Instalando en el dispositivo conectado...' -ForegroundColor Yellow

    if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
        Write-Host 'ADB no esta disponible en PATH. Instala Android platform-tools o agrega adb al PATH.' -ForegroundColor Red
        exit 1
    }

    $devices = adb devices | Select-Object -Skip 1 | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    $connectedDevices = @($devices | Where-Object { $_ -match '\sdevice$' })

    if ($connectedDevices.Count -eq 0) {
        Write-Host 'No se detecto ningun dispositivo Android autorizado.' -ForegroundColor Red
        Write-Host 'Activa la depuracion USB, conecta el celular y acepta la huella RSA.' -ForegroundColor Yellow
        exit 1
    }

    if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
        adb -s $DeviceId install -r $apkPath
    } elseif ($connectedDevices.Count -eq 1) {
        $DeviceId = ($connectedDevices[0] -split '\s+')[0]
        adb -s $DeviceId install -r $apkPath
    } else {
        Write-Host 'Hay mas de un dispositivo conectado. Vuelve a ejecutar el script con -DeviceId <id>.' -ForegroundColor Red
        Write-Host 'Dispositivos detectados:' -ForegroundColor Yellow
        $connectedDevices | ForEach-Object { Write-Host " - $_" }
        exit 1
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Fallo la instalacion del APK.' -ForegroundColor Red
        exit 1
    }

    Write-Host 'APK instalado correctamente en el dispositivo.' -ForegroundColor Green
}

Write-Host 'Listo.' -ForegroundColor Cyan