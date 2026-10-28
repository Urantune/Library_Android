param([int]$Port = 8081)
$ErrorActionPreference = 'Stop'
$moduleRoot = Join-Path $PSScriptRoot 'identity-service'
$dataRoot = Join-Path $moduleRoot 'data'
New-Item -ItemType Directory -Path $dataRoot -Force | Out-Null
$oldValues = @{}
foreach ($key in @('DB_PATH', 'AUTH_KEY_DIR', 'EUREKA_CLIENT_ENABLED', 'SPRING_CLOUD_DISCOVERY_ENABLED', 'SERVER_PORT')) {
    $oldValues[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
}
try {
    if (-not $env:DB_PATH) { $env:DB_PATH = Join-Path $dataRoot 'identity.db' }
    if (-not $env:AUTH_KEY_DIR) { $env:AUTH_KEY_DIR = Join-Path $dataRoot 'auth-keys' }
    $env:EUREKA_CLIENT_ENABLED = 'false'
    $env:SPRING_CLOUD_DISCOVERY_ENABLED = 'false'
    $env:SERVER_PORT = "$Port"
    Push-Location $moduleRoot
    try {
        & .\mvnw.cmd spring-boot:run
        if ($LASTEXITCODE -ne 0) { throw 'Identity startup failed' }
    } finally { Pop-Location }
} finally {
    foreach ($key in $oldValues.Keys) { [Environment]::SetEnvironmentVariable($key, $oldValues[$key], 'Process') }
}
