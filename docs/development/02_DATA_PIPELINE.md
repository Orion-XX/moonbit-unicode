# Unicode Data Pipeline

## Pinned Inputs

Use Unicode 16.0.0 only for the first release. Store inputs below
`unicode/data/16.0.0/` and describe each in `manifest.json` with source URL,
SHA-256, Unicode version, and license notice.

Required files:

- `UnicodeData.txt`: canonical decomposition and CCC;
- `CompositionExclusions.txt`: NFC exclusions;
- `DerivedNormalizationProps.txt`: normalization properties and verification;
- `GraphemeBreakProperty.txt`: grapheme-break property;
- `emoji-data.txt`: `Extended_Pictographic` property;
- `NormalizationTest.txt`: normalization conformance input;
- `auxiliary/GraphemeBreakTest.txt`: grapheme conformance input.

Canonical URLs begin at `https://www.unicode.org/Public/16.0.0/ucd/`.
The generator must reject a manifest/file version mismatch and hash mismatch.

## Generator Outputs

The generator creates only deterministic source and test fixtures:

```text
src/internal/tables/normalization_data.mbt
src/internal/tables/grapheme_data.mbt
tests/conformance/generated_normalization_cases.mbt
tests/conformance/generated_grapheme_cases.mbt
```

Every generated file begins with an ASCII header containing the Unicode version,
input file names and hashes, generator version/command, and `DO NOT EDIT`.

## Generator Commands

The command names are set by U-00. See
[U-00 commands and handoff](U00_COMMANDS_AND_HANDOFF.md) for the current
fail-closed scaffold behavior and target evidence. Their eventual required
semantics are:

```powershell
moon run tools/unicode-gen -- generate --data unicode/data/16.0.0
moon run tools/unicode-gen -- check --data unicode/data/16.0.0
moon run tools/unicode-gen -- import-tests --data unicode/data/16.0.0
```

`check` generates into a temporary location or compares in-memory output and
fails if committed generated files differ. `import-tests` must preserve source
line identifiers for failure reporting.

## Representation Requirements

- Prefer sorted ranges with binary search or a measured compact trie/range
  encoding. Do not choose compression solely by aesthetics.
- Use algorithmic Hangul decomposition/composition; do not store 11,172 manual
  syllable mappings.
- Keep recursive canonical mappings, CCC, composition pairs/exclusions,
  grapheme properties, and Extended_Pictographic separate in the intermediate
  model, even if some final tables share an encoding.
- Generated code must compile on native, wasm, wasm-gc, and js without FFI.

## Failure Handling

A generator parse error must identify the input filename and source line. A
duplicate or conflicting property assignment is an error. Unknown data needed
by a required rule is an error. Do not substitute values from host Unicode/ICU.
