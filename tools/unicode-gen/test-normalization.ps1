$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$data = Join-Path $root 'unicode/data/16.0.0'
$script = Join-Path $PSScriptRoot 'normalization_conformance.py'
python $script --import-tests --data $data
python $script --check --data $data
moon test tests/conformance
