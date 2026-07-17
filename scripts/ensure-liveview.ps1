param(
  [string]$Root = $(if ($env:CODEX_LIVEVIEW_ROOT) { $env:CODEX_LIVEVIEW_ROOT } else { 'C:\inetpub\wwwroot\Codex LiveView' }),
  [string]$HealthUrl = 'http://127.0.0.1:4173/api/evidence/health',
  [int]$TimeoutSeconds = 15
)

function Get-LiveViewHealth {
  try {
    return Invoke-RestMethod -Uri $HealthUrl -Method Get -TimeoutSec 2
  } catch {
    return $null
  }
}

$health = Get-LiveViewHealth
if ($null -ne $health) {
  Write-Output "status=already-running"
  Write-Output "health=$($health.status)"
  exit 0
}

if (-not (Test-Path -LiteralPath (Join-Path $Root 'package.json'))) {
  Write-Error "LiveView root does not contain package.json: $Root"
  exit 2
}

$process = Start-Process -FilePath 'npm.cmd' -ArgumentList @('start') -WorkingDirectory $Root -WindowStyle Hidden -PassThru
$deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)

while ([DateTime]::UtcNow -lt $deadline) {
  Start-Sleep -Milliseconds 250
  $health = Get-LiveViewHealth
  if ($null -ne $health) {
    Write-Output "status=started"
    Write-Output "pid=$($process.Id)"
    Write-Output "health=$($health.status)"
    exit 0
  }
}

if (-not $process.HasExited) {
  Stop-Process -Id $process.Id -Force
}

Write-Error "LiveView did not respond at $HealthUrl within $TimeoutSeconds seconds."
exit 1
