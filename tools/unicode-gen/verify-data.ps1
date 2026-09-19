param([string]$DataPath = 'unicode/data/16.0.0')
$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $DataPath 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "manifest missing: $manifestPath" }
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
if ($manifest.unicode_version -ne '16.0.0') { throw "manifest version mismatch: $($manifest.unicode_version)" }
foreach ($entry in $manifest.files) {
  $path = Join-Path $DataPath $entry.path
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "input missing: $($entry.path)" }
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
  if ($actual -ne $entry.sha256.ToLowerInvariant()) { throw "hash mismatch: $($entry.path) (expected $($entry.sha256), got $actual)" }
}
$license = Join-Path $DataPath $manifest.license.file
if (-not (Test-Path -LiteralPath $license -PathType Leaf)) { throw "license missing: $($manifest.license.file)" }
Write-Output "verified Unicode $($manifest.unicode_version): $($manifest.files.Count) inputs; license=$($manifest.license.file)"
