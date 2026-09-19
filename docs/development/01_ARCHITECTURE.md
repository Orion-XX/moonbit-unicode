# Architecture

## Target Layout

```text
moon.mod
src/
  normalization/       Public NFC/NFD APIs and algorithm stages
  grapheme/            Public iterator and UAX #29 boundary state machine
  internal/tables/     Generated, private lookup tables only
tools/unicode-gen/     Offline generator executable/package
unicode/data/16.0.0/   Pinned upstream inputs, manifest, license notice
tests/conformance/     Imported vector runners and generated fixtures
tests/property/        QuickCheck properties and regressions
bench/                 Target-neutral benchmark entry points
```

`internal/tables` is generated and private. Public packages must not expose
Unicode table representation.

## Data Flow

```text
Pinned UCD files -> unicode-gen parser -> normalized intermediate records
-> deterministic MoonBit table source -> normalization/grapheme runtime APIs
-> unit, property, conformance, target, and benchmark evidence
```

The generator reads local files only. CI downloads are a separate, explicit
maintenance workflow; normal tests never fetch Unicode data.

## Normalization Design

NFD is exactly: recursive canonical decomposition, algorithmic Hangul
decomposition, then canonical ordering by canonical combining class (CCC).

NFC is exactly: NFD pipeline followed by canonical composition, including
algorithmic Hangul composition, subject to composition exclusion and blocking
rules. Compatibility mappings are parsed only if needed to distinguish and
exclude them; they are not exposed or emitted as an NFK* feature.

Implement the stages as internal functions with focused tests:

```text
decompose_canonical -> reorder_canonical -> compose_canonical
```

## Grapheme Design

Implement UAX #29 extended grapheme clusters as a forward state machine over
Unicode scalars. Generated tables provide grapheme-break properties and the
Extended_Pictographic predicate. The state machine owns rule context required
by GB11 and GB12/GB13; it must not rely on a regex or JavaScript API.

The iterator yields string slices or `(start_byte, end_byte)` boundaries. Pick
one representation in U-10 and document lifetime/allocation behavior before
publishing it. It must never split inside a valid UTF-8 scalar boundary.

## Public API Contract

Initial names are intentionally small and may be adjusted only in U-07/U-10:

```mbt
pub fn nfd(input : String) -> String
pub fn nfc(input : String) -> String
pub fn grapheme_boundaries(input : String) -> Iter[(Int, Int)]
```

The tuple is byte offsets with an end-exclusive range. An eventual allocating
`graphemes` convenience function is optional and must be built on boundaries.

## Ownership

| Area | Owner task group | Must not do |
|---|---|---|
| UCD parsing and tables | U-01..U-03, U-09 | hand-edit generated tables |
| normalization runtime | U-04..U-07 | add compatibility normalization |
| grapheme runtime | U-10 | change UCD generator semantics |
| conformance harness | U-08, U-11 | silently filter failures |
| quality/release | U-12..U-14 | alter algorithm behavior for benchmarks |
