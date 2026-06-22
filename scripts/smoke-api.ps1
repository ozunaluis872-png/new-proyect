param(
    [string]$BaseUrl = "http://localhost:5105/api",
    [string]$Correo = "admin@loginova.com",
    [string]$Password = "admin123"
)

$ErrorActionPreference = "Stop"

function To-Array {
    param($Value)

    if ($null -eq $Value) {
        return @()
    }

    if ($Value -is [System.Array]) {
        return $Value
    }

    return @($Value)
}

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw "[FAIL] $Message"
    }

    Write-Host "[OK] $Message" -ForegroundColor Green
}

Write-Host "== Smoke API Loginova ==" -ForegroundColor Cyan
Write-Host "BaseUrl: $BaseUrl"

$invalidLoginOk = $false
try {
    $invalidBody = @{ correo = $Correo; password = "password-invalido" } | ConvertTo-Json
    Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -ContentType "application/json" -Body $invalidBody | Out-Null
} catch {
    $response = $_.Exception.Response
    if ($null -ne $response -and $response.StatusCode.value__ -eq 401) {
        $invalidLoginOk = $true
    }
}
Assert-True $invalidLoginOk "Login invalido es rechazado con 401"

$loginBody = @{ correo = $Correo; password = $Password } | ConvertTo-Json
$loginResp = Invoke-RestMethod -Uri "$BaseUrl/auth/login" -Method Post -ContentType "application/json" -Body $loginBody

Assert-True (-not [string]::IsNullOrWhiteSpace($loginResp.token)) "Login devuelve token"

$headers = @{ Authorization = "Bearer $($loginResp.token)" }

$usuarios = To-Array ((Invoke-WebRequest -Uri "$BaseUrl/usuarios" -Method Get -Headers $headers -UseBasicParsing).Content | ConvertFrom-Json)
Assert-True ($usuarios.Count -gt 0) "Listado de usuarios disponible"

$usuarioId = $usuarios[0].id
Assert-True ($usuarioId -gt 0) "Usuario valido para prueba"

$testClienteBody = @{
    nombre = "Cliente Smoke $(Get-Date -Format yyyyMMddHHmmss)"
    telefono = "3009990000"
    direccion = "Direccion smoke"
    ciudad = "Bogota"
} | ConvertTo-Json

$clienteResp = Invoke-WebRequest -Uri "$BaseUrl/clientes" -Method Post -Headers $headers -ContentType "application/json" -Body $testClienteBody -UseBasicParsing
Assert-True ($clienteResp.StatusCode -eq 201) "Creacion de cliente responde 201"

$clienteCreado = $clienteResp.Content | ConvertFrom-Json
Assert-True ($clienteCreado.id -gt 0) "Cliente creado con ID valido"

$clienteId = $clienteCreado.id

$clienteUpdateBody = @{
    nombre = "$($clienteCreado.nombre) Actualizado"
    telefono = "3009991111"
    direccion = "Direccion smoke actualizada"
    ciudad = "Medellin"
} | ConvertTo-Json

$clienteUpdateResp = Invoke-WebRequest -Uri "$BaseUrl/clientes/$clienteId" -Method Put -Headers $headers -ContentType "application/json" -Body $clienteUpdateBody -UseBasicParsing
Assert-True ($clienteUpdateResp.StatusCode -eq 204) "Actualizacion de cliente responde 204"

$recBody = @{
    clienteId = $clienteId
    usuarioId = $usuarioId
    estado = "Pendiente"
    cantidadPaquetes = 2
    observaciones = "Smoke test $(Get-Date -Format s)"
} | ConvertTo-Json

try {
    $recResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas" -Method Post -Headers $headers -ContentType "application/json" -Body $recBody -UseBasicParsing
} catch {
    $res = $_.Exception.Response
    if ($null -ne $res) {
        $reader = New-Object System.IO.StreamReader($res.GetResponseStream())
        $body = $reader.ReadToEnd()
        throw "[FAIL] Error creando recogida. Status=$($res.StatusCode.value__) Body=$body"
    }

    throw
}
Assert-True ($recResp.StatusCode -eq 201) "Creacion de recogida responde 201"

$recCreada = $recResp.Content | ConvertFrom-Json
Assert-True ($recCreada.id -gt 0) "Recogida creada con ID valido"

$recUpdateBody = @{
    clienteId = $recCreada.clienteId
    usuarioId = $recCreada.usuarioId
    estado = "En Ruta"
    cantidadPaquetes = 5
    observaciones = "Smoke test actualizado"
} | ConvertTo-Json

$recUpdateResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas/$($recCreada.id)" -Method Put -Headers $headers -ContentType "application/json" -Body $recUpdateBody -UseBasicParsing
Assert-True ($recUpdateResp.StatusCode -eq 204) "Actualizacion de recogida responde 204"

$eviBody = @{
    recogidaId = $recCreada.id
    fotoUrl = "C:/tmp/evidencia-smoke.jpg"
    comentario = "Evidencia smoke test"
} | ConvertTo-Json

$eviResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias" -Method Post -Headers $headers -ContentType "application/json" -Body $eviBody -UseBasicParsing
Assert-True ($eviResp.StatusCode -eq 201) "Creacion de evidencia responde 201"

$eviCreada = $eviResp.Content | ConvertFrom-Json
Assert-True ($eviCreada.id -gt 0) "Evidencia creada con ID valido"

$evidenciasRecogidaResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias/recogida/$($recCreada.id)" -Method Get -Headers $headers -UseBasicParsing
Assert-True ($evidenciasRecogidaResp.StatusCode -eq 200) "Consulta de evidencias por recogida responde 200"

$evidenciasRecogida = To-Array ($evidenciasRecogidaResp.Content | ConvertFrom-Json)
Assert-True ($null -ne $evidenciasRecogida) "Consulta de evidencias por recogida disponible"

$eviByIdResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias/$($eviCreada.id)" -Method Get -Headers $headers -UseBasicParsing
Assert-True ($eviByIdResp.StatusCode -eq 200) "Consulta de evidencia por ID responde 200"

$eviById = $eviByIdResp.Content | ConvertFrom-Json
Assert-True ($eviById.id -eq $eviCreada.id) "Consulta por ID devuelve la evidencia creada"

$deleteEviResp = Invoke-WebRequest -Uri "$BaseUrl/evidencias/$($eviCreada.id)" -Method Delete -Headers $headers -UseBasicParsing
Assert-True ($deleteEviResp.StatusCode -eq 204) "Eliminacion de evidencia responde 204"

$recogidas = To-Array ((Invoke-WebRequest -Uri "$BaseUrl/recogidas" -Method Get -Headers $headers -UseBasicParsing).Content | ConvertFrom-Json)
Assert-True ($recogidas.Count -gt 0) "Listado de recogidas disponible"

$idEncontrado = $false
foreach ($r in $recogidas) {
    if ($r.id -eq $recCreada.id) {
        $idEncontrado = $true
        break
    }
}
Assert-True $idEncontrado "Recogida creada aparece en el listado"

$deleteRecResp = Invoke-WebRequest -Uri "$BaseUrl/recogidas/$($recCreada.id)" -Method Delete -Headers $headers -UseBasicParsing
Assert-True ($deleteRecResp.StatusCode -eq 204) "Eliminacion de recogida responde 204"

$deleteClienteResp = Invoke-WebRequest -Uri "$BaseUrl/clientes/$clienteId" -Method Delete -Headers $headers -UseBasicParsing
Assert-True ($deleteClienteResp.StatusCode -eq 204) "Eliminacion de cliente de prueba responde 204"

Write-Host "" 
Write-Host "Smoke test completado correctamente." -ForegroundColor Cyan
