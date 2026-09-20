# U-11 handoff: grapheme conformance

U-11 adds a deterministic offline importer and a public-API conformance test
for every non-comment vector in Unicode 16.0.0
`auxiliary/GraphemeBreakTest.txt`. The generated fixture retains each source
line, scalar sequence, scalar break indexes, and the complete source decision
syntax using ASCII `D`/`X` markers (`D` is a break and `X` is no-break).
Expected byte ranges are derived from scalar indexes only in the MoonBit test,
after constructing the input `String`.

The pinned input SHA-256 is
`0866f99df6975f15e2dae2475ae243dd4e1b530ade5fb796f0c49f7e019ced50`.
The importer generated **1,093** vectors in
`tests/conformance/generated_grapheme_cases.mbt`.

Commands run from the U-11 worktree:

```text
python tools/unicode-gen/grapheme_conformance.py --import-tests --data unicode/data/16.0.0
python tools/unicode-gen/grapheme_conformance.py --check --data unicode/data/16.0.0
moon fmt
moon info
moon test tests/conformance
```

The importer and deterministic check pass. The conformance test compiles and
executes all 1,093 vectors, but the current U-10 runtime fails Unicode 16
Indic conjunct vectors requiring GB9c. The first diagnostic is source line
1108 (`0915 × 094D × 0924`), where expected `(0, 9)` and actual
`(0, 6), (6, 9)`. The test reports every non-pass with source line, target,
API, input scalars, expected/actual byte ranges, and encoded source syntax.
Therefore the U-11 acceptance count is currently **1,092 passed, 1 failed,
0 skipped** only if the test is run against a runtime that has exactly one
failure; the observed run stopped at the first failure before the aggregate
diagnostic update was verified. No vector is skipped or rewritten.

The failure is outside U-11's allowed paths and must be fixed in the U-10
grapheme state machine before this branch can be considered PR-ready.
