# API and Test Contract

## String and Invalid Input Semantics

Public APIs accept MoonBit `String`. They operate on the scalar sequence already
represented by that string and inherit core's construction/decoding behavior.
They do not accept raw byte buffers and must not add a second UTF-8 decoder.
Any future byte-oriented API is a separate proposal with an explicit strict or
lossy decoding contract.

## Normalization Requirements

`nfd` and `nfc` return a string canonically equivalent to input in the named
form under Unicode 16.0. Both preserve empty and ASCII strings semantically.
They must satisfy:

```text
nfd(nfd(x)) == nfd(x)
nfc(nfc(x)) == nfc(x)
nfc(nfd(x)) == nfc(x)
```

The implementation must handle non-starter runs, canonical blocking,
composition exclusions, and Hangul. It must not perform compatibility mappings.

## Grapheme Requirements

`grapheme_boundaries` returns ascending, non-overlapping, end-exclusive byte
ranges. For non-empty input the first range starts at 0 and the final range
ends at `input.length()`. Concatenating all ranges reconstructs input exactly.

Required cases include CR/LF, controls, Extend, SpacingMark, Prepend, Hangul
L/V/T sequences, ZWJ emoji sequences, Extended_Pictographic, and Regional
Indicator pairs. Empty input produces no ranges.

## Test Layers

| Layer | Oracle | Required behavior |
|---|---|---|
| unit | targeted examples | isolate each algorithm stage/rule |
| generated conformance | Unicode 16.0 files | all applicable cases pass |
| property | core quickcheck | idempotence and range invariants |
| regression | prior bug vector | fixed seed/case and issue reference |
| target | Moon test runner | run and report each backend separately |

Do not use host `unicodedata`, ICU, or `Intl.Segmenter` as a runtime oracle.
They may be used only by a documented, non-blocking local differential tool and
never to overwrite expected vectors.

## Failure Report Format

Conformance failures must include Unicode source file, source line, input code
points, expected output/boundaries, actual output/boundaries, and target. A
failure message that only prints rendered text is insufficient because visually
equal strings can differ by scalar sequence.
