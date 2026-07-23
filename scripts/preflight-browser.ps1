param(
  [string]$ProjectRoot = (Get-Location).Path,
  [string]$EvidenceRoot = $(if ($env:CODEX_LIVEVIEW_EVIDENCE_ROOT) { $env:CODEX_LIVEVIEW_EVIDENCE_ROOT } else { Join-Path $env:TEMP 'codex-liveview' }),
  [string]$HealthUrl = 'http://127.0.0.1:4173/api/evidence/health',
  [string]$ProbeUrl = ''
)

function Test-AnyPath([string[]]$Paths) {
  return @($Paths | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) }).Count -gt 0
}

$chromePaths = @(
  (Join-Path $env:ProgramFiles 'Google\Chrome\Application\chrome.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Google\Chrome\Application\chrome.exe'),
  (Join-Path $env:LOCALAPPDATA 'Google\Chrome\Application\chrome.exe')
)
$edgePaths = @(
  (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
  (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe')
)
$nodeAvailable = $null -ne (Get-Command node.exe -ErrorAction SilentlyContinue)
$playwrightAvailable = Test-Path -LiteralPath (Join-Path $ProjectRoot 'node_modules\playwright')
$httpAvailable = $null -ne (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue)

$liveViewStatus = 'unavailable'
try {
  $health = Invoke-RestMethod -Uri $HealthUrl -Method Get -TimeoutSec 2
  if ($health.status) { $liveViewStatus = [string]$health.status }
} catch { }

$probeStatus = 'not-requested'
if ($ProbeUrl) {
  try {
    $probe = Invoke-WebRequest -Uri $ProbeUrl -Method Head -TimeoutSec 5 -UseBasicParsing
    $probeStatus = "HTTP $($probe.StatusCode)"
  } catch {
    $probeStatus = 'unavailable'
  }
}

Write-Output 'preflight=complete'
Write-Output 'shared-browser-tab=report-from-browser-tool'
Write-Output "chrome=$(if (Test-AnyPath $chromePaths) { 'available' } else { 'unavailable' })"
Write-Output "edge=$(if (Test-AnyPath $edgePaths) { 'available' } else { 'unavailable' })"
Write-Output "node=$(if ($nodeAvailable) { 'available' } else { 'unavailable' })"
Write-Output "playwright=$(if ($playwrightAvailable) { 'available' } else { 'unavailable' })"
Write-Output "screenshot-root=$(if (Test-Path -LiteralPath $EvidenceRoot -PathType Container) { 'available' } else { 'unavailable' })"
Write-Output "independent-http=$(if ($httpAvailable) { 'available' } else { 'unavailable' })"
Write-Output "liveview-health=$liveViewStatus"
Write-Output "independent-probe=$probeStatus"
Write-Output 'install-actions=none'
