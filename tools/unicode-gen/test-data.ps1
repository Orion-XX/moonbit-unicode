$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$data = Join-Path $root 'unicode/data/16.0.0'
& (Join-Path $PSScriptRoot 'verify-data.ps1') -DataPath $data
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('unicode-u01-' + [guid]::NewGuid())
Copy-Item -Recurse -LiteralPath $data -Destination $tmp
try {
  Add-Content -LiteralPath (Join-Path $tmp 'UnicodeData.txt') -Value '# U-01 mismatch probe'
  try { & (Join-Path $PSScriptRoot 'verify-data.ps1') -DataPath $tmp; throw 'expected hash mismatch was not reported' }
  catch { if (-not $_.Exception.Message.Contains('hash mismatch: UnicodeData.txt')) { throw } }
  Write-Output 'PASS mismatch reports filename: UnicodeData.txt'
  $manifest = Get-Content -Raw -LiteralPath (Join-Path $tmp 'manifest.json') | ConvertFrom-Json
  $manifest.files[0].sha256 = ('0' * 64)
  $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $tmp 'manifest.json')
  try { & (Join-Path $PSScriptRoot 'verify-data.ps1') -DataPath $tmp; throw 'expected manifest mismatch was not reported' }
  catch { if (-not $_.Exception.Message.Contains('hash mismatch: UnicodeData.txt')) { throw } }
  Write-Output 'PASS manifest mismatch reports filename: UnicodeData.txt'
} finally { Remove-Item -Recurse -Force -LiteralPath $tmp }
