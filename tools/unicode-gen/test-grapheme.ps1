$ErrorActionPreference = 'Stop'
$data = 'unicode/data/16.0.0'
$script = 'tools/unicode-gen/grapheme_conformance.py'
python $script --import-tests --data $data
python $script --check --data $data
