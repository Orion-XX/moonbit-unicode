param(
    [ValidateSet('native', 'wasm', 'wasm-gc', 'js')]
    [string]$Target = 'native'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Push-Location (Join-Path $PSScriptRoot '../..')
try {
    # Keep the U-00 rejection contract while allowing later tasks to implement
    # the reserved commands without rewriting this target matrix.
    $cases = @(
        @{ Args = @('check', '--data', 'unicode/data/16.0.0'); Legacy = "U-00 scaffold: check unavailable for data path 'unicode/data/16.0.0'"; Implemented = 'unicode-gen: check verified Unicode 16.0.0 data at unicode/data/16.0.0' },
        @{ Args = @('generate', '--data', 'unicode/data/16.0.0'); Legacy = 'U-00 scaffold: generate unavailable'; Implemented = 'unicode-gen: generate verified Unicode 16.0.0 data at unicode/data/16.0.0' },
        @{ Args = @('import-tests', '--data', 'unicode/data/16.0.0'); Legacy = 'U-00 scaffold: import-tests unavailable'; Implemented = 'unicode-gen: import-tests verified Unicode 16.0.0 data at unicode/data/16.0.0' },
        @{ Args = @('check'); Legacy = 'unicode-gen: usage:' }
    )
    foreach ($case in $cases) {
        $cliArgs = $case.Args
        $output = & moon run tools/unicode-gen --target $Target -- @cliArgs 2>&1
        $code = $LASTEXITCODE
        $text = $output -join "`n"
        $implemented = $null -ne $case.Implemented -and $code -eq 0 -and $text.Contains($case.Implemented)
        $legacy = $code -ne 0 -and $text.Contains($case.Legacy)
        if (-not ($implemented -or $legacy)) {
            throw "CLI contract failed ($Target, $($cliArgs -join ' '), exit=$code):`n$text"
        }
        Write-Output "PASS CLI contract: target=$Target args=$($cliArgs -join ' ') exit=$code"
    }
    exit 0
} finally {
    Pop-Location
}
