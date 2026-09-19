# U-01 handoff: pinned Unicode inputs

The U-00 dependency is complete (the project skeleton and native baseline are
present). U-01 pins Unicode **16.0.0** in `unicode/data/16.0.0/`.

The manifest covers `UnicodeData.txt`, `CompositionExclusions.txt`,
`DerivedNormalizationProps.txt`, `GraphemeBreakProperty.txt`, `emoji-data.txt`,
`NormalizationTest.txt`, and `auxiliary/GraphemeBreakTest.txt`. Each entry has
its official Unicode URL and SHA-256. `LICENSE.txt` is pinned separately with
its URL and SHA-256 and retains the Unicode copyright notice.

Commands run from PowerShell at the module root:

```text
moon info                         # pass
moon fmt                          # pass
moon test                         # 3 passed, 0 failed
./tools/unicode-gen/verify-data.ps1 -DataPath unicode/data/16.0.0
                                  # verified 7 inputs; license=LICENSE.txt
./tools/unicode-gen/test-data.ps1 # input and manifest mismatch probes pass
moon run tools/unicode-gen -- check --data unicode/data/16.0.0
                                  # U-00 fail-closed scaffold (nonzero)
```

The verifier reports the first failing filename for both a changed input and a
changed manifest digest. It performs no network access. The MoonBit `check`
entry point remains the U-00 fail-closed placeholder because the current core
runtime has no portable filesystem/hash API; U-02 owns the parser-side command
integration. The actual U-01 acceptance verifier is the PowerShell command
above and is the maintenance command documented for Windows.

No U-02 parsing, generated tables, normalization runtime, grapheme runtime, or
conformance tests were added.
