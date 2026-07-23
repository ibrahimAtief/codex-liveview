param(
  [Parameter(Mandatory = $true)]
  [string]$SnapshotPath,
  [string]$Root = $(if ($env:CODEX_LIVEVIEW_ROOT) { $env:CODEX_LIVEVIEW_ROOT } else { 'C:\inetpub\wwwroot\Codex LiveView' }),
  [string]$EvidenceUrl = 'http://127.0.0.1:4173/api/evidence',
  [string]$HealthUrl = 'http://127.0.0.1:4173/api/evidence/health',
  [int]$TimeoutSeconds = 15
)

if (-not (Test-Path -LiteralPath $SnapshotPath -PathType Leaf)) {
  Write-Error "Snapshot JSON was not found: $SnapshotPath"
  Write-Output 'published=false'
  exit 2
}

try {
  $snapshot = Get-Content -LiteralPath $SnapshotPath -Raw | ConvertFrom-Json
  $body = $snapshot | ConvertTo-Json -Depth 20 -Compress
} catch {
  Write-Error "Snapshot JSON could not be read: $($_.Exception.Message)"
  Write-Output 'published=false'
  exit 2
}

$readinessScript = Join-Path $PSScriptRoot 'ensure-liveview.ps1'
$readinessOutput = & $readinessScript -Root $Root -HealthUrl $HealthUrl -TimeoutSeconds $TimeoutSeconds 2>&1
$readinessExitCode = $LASTEXITCODE
$readinessOutput | ForEach-Object { Write-Output $_ }

if ($readinessExitCode -ne 0) {
  Write-Error 'LiveView was not ready; evidence was not published.'
  Write-Output 'published=false'
  exit 1
}

try {
  $response = Invoke-RestMethod -Uri $EvidenceUrl -Method Post -ContentType 'application/json' -Body $body -TimeoutSec 10
  Write-Output 'published=true'
  Write-Output "receivedAt=$($response.receivedAt)"
  exit 0
} catch {
  Write-Error "Evidence publish failed: $($_.Exception.Message)"
  Write-Output 'published=false'
  exit 1
}
