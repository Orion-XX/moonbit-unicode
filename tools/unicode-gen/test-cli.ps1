param(
    [ValidateSet('native', 'wasm', 'wasm-gc', 'js')]
    [string]$Target = 'native'
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Push-Location (Join-Path $PSScriptRoot '../..')
try {
    # A compiler/runner failure must not masquerade as the expected CLI error.
    $cases = @(
        @{ Args = @('check', '--data', 'unicode/data/16.0.0'); Expected = "U-00 scaffold: check unavailable for data path 'unicode/data/16.0.0'" },
        @{ Args = @('generate', '--data', 'unicode/data/16.0.0'); Expected = 'U-00 scaffold: generate unavailable' },
        @{ Args = @('import-tests', '--data', 'unicode/data/16.0.0'); Expected = 'U-00 scaffold: import-tests unavailable' },
        @{ Args = @('check'); Expected = 'unicode-gen: usage:' }
    )
    foreach ($case in $cases) {
        $cliArgs = $case.Args
        $output = & moon run tools/unicode-gen --target $Target -- @cliArgs 2>&1
        $code = $LASTEXITCODE
        $text = $output -join "`n"
        if ($code -eq 0 -or -not $text.Contains($case.Expected)) {
            throw "CLI contract failed ($Target, $($cliArgs -join ' '), exit=$code):`n$text"
        }
        Write-Output "PASS expected rejection: target=$Target args=$($cliArgs -join ' ') exit=$code"
    }
} finally {
    Pop-Location
}
