param(
  [Parameter(Mandatory = $true)]
  [string]$SnapshotPath,
  [string]$OutputPath = '',
  [ValidateSet('published', 'unpublished', 'not-tested')]
  [string]$Handoff = 'not-tested',
  [string]$ApproximateToolCalls = 'not-recorded',
  [string]$RepeatedWork = 'none-recorded'
)

if (-not (Test-Path -LiteralPath $SnapshotPath -PathType Leaf)) {
  Write-Error "Snapshot JSON was not found: $SnapshotPath"
  exit 2
}

try {
  $snapshot = Get-Content -LiteralPath $SnapshotPath -Raw | ConvertFrom-Json
} catch {
  Write-Error "Snapshot JSON could not be read: $($_.Exception.Message)"
  exit 2
}

function Get-Classification($asset) {
  if ($asset.classification) { return [string]$asset.classification }
  if ($asset.status -ge 400) { return 'failed' }
  return 'loaded'
}

$assets = @($snapshot.assets)
$loaded = @($assets | Where-Object { (Get-Classification $_) -eq 'loaded' }).Count
$failed = @($assets | Where-Object { (Get-Classification $_) -eq 'failed' }).Count
$blocked = @($assets | Where-Object { (Get-Classification $_) -eq 'environment-blocked' }).Count
$notTested = @($assets | Where-Object { (Get-Classification $_) -eq 'not-tested' }).Count
$errors = @($snapshot.console.errors).Count
$warnings = @($snapshot.console.warnings).Count
$probes = @($snapshot.network.independentProbes)
$probeSuccess = @($probes | Where-Object { $_.status -ge 200 -and $_.status -lt 400 }).Count
$probeFailures = $probes.Count - $probeSuccess
$assetSummary = "$loaded loaded · $failed failed"
if ($blocked) { $assetSummary += " · $blocked environment-blocked" }
if ($notTested) { $assetSummary += " · $notTested not-tested" }

$viewport = "$($snapshot.viewport.width)x$($snapshot.viewport.height)"
$document = "$($snapshot.document.width)x$($snapshot.document.height)"
$raster = if ($snapshot.screenshot.raster) { "$($snapshot.screenshot.raster.width)x$($snapshot.screenshot.raster.height)" } else { 'not-recorded' }
$overflow = if ($snapshot.layout.status -eq 'overflow') { "$($snapshot.layout.overflowPixels)px" } else { 'none' }
$screenshot = if ($snapshot.screenshot.path) { "$($snapshot.screenshot.path) [$($snapshot.screenshot.integrity)]" } else { 'none' }
$independent = if ($probes.Count) { "$probeSuccess HTTP success · $probeFailures HTTP failures" } else { 'not-tested' }
$ready = if ($snapshot.readyState) { $snapshot.readyState } else { 'not-recorded' }
$phase = if ($snapshot.phase) { $snapshot.phase } else { 'not-recorded' }
$page = if ($snapshot.url) { $snapshot.url } else { 'not-recorded' }

$editReady = $phase -eq 'settled-result' -and $ready -eq 'complete' -and $failed -eq 0 -and $errors -eq 0 -and $overflow -eq 'none' -and (!$snapshot.screenshot.path -or $snapshot.screenshot.integrity -eq 'verified')
$inference = if ($editReady) { 'edit-ready' } else { 'needs-review' }

$lines = @(
  "observed: project=$($snapshot.projectName) session=$($snapshot.sessionId) phase=$phase page=$page readiness=$ready viewport=$viewport document=$document raster=$raster assets=$assetSummary console=$errors errors/$warnings warnings overflow=$overflow screenshot=$screenshot",
  "independent-verification: http=$independent handoff=$Handoff",
  "inference: decision=$inference approximate-tool-calls=$ApproximateToolCalls repeated-work=$RepeatedWork"
)

if ($OutputPath) {
  $lines | Set-Content -LiteralPath $OutputPath -Encoding utf8
  Write-Output "report-path=$OutputPath"
}
$lines | ForEach-Object { Write-Output $_ }
