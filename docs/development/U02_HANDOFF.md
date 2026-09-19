# U-02 handoff: UCD intermediate parser

U-01 is complete and remains the only data dependency. This task adds the
typed, source-located parser in `tools/unicode-gen/parser.mbt` and focused
white-box fixtures in `tools/unicode-gen/parser_wbtest.mbt`.

The parser covers UCD semicolon/property records, scalar and range validation,
canonical and compatibility decomposition mappings, CCC, composition
exclusions, Extended_Pictographic/grapheme properties, and semicolon-separated
normalization/grapheme conformance vectors. Every record and every diagnostic
retains the input filename and one-based source line. Overlap, contradictory
duplicates, malformed scalars, missing fields, and malformed vectors are
rejected. No runtime package imports this parser and no generated tables are
produced by U-02.

Unicode input boundary: 16.0.0, using the seven files pinned by
`unicode/data/16.0.0/manifest.json`.

Commands run from PowerShell at the module root:

```text
moon info
moon fmt
moon test --target native
./tools/unicode-gen/verify-data.ps1 -DataPath unicode/data/16.0.0
```

Results: `moon test --target native` passed 9/9 parser and existing scaffold
tests; the pinned-data verifier reported all 7 inputs and the license as
verified. Wasm, wasm-gc, and JavaScript runners were not executed in this
handoff. The existing `moon run tools/unicode-gen -- check` remains the U-00
fail-closed CLI scaffold; file-backed command integration is intentionally
owned by the next generator task and is not claimed here.
