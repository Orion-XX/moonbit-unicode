# Project Brief: MoonBit Unicode Text

## Outcome

Deliver a MoonBit package with a reproducible Unicode 16.0 data pipeline and
three public capabilities:

- `nfd(input : String) -> String`
- `nfc(input : String) -> String`
- a lazy extended-grapheme-cluster iterator over `String`

The implementation must pass the pinned Unicode normalization and grapheme
conformance suites on every supported target that can run in CI.

## Users and Use Cases

- editors and terminal tools that must move or truncate by grapheme cluster;
- search/indexing tools that need canonical normalization;
- protocol and CLI authors who need portable, target-independent behavior.

## Explicit Boundary

MoonBit core already owns UTF-8 decoding and iteration over Unicode scalar
values. This project consumes those APIs. It does not replace `String`, `Char`,
UTF-8 decoding, or `moonbitlang/core/quickcheck`.

The first release excludes NFKC/NFKD, case mapping/folding, word/line breaks,
collation, bidi, locale APIs, confusable detection, IDNA, and complete ICU
compatibility.

## Release Definition

Release 0.1 is acceptable only when all of the following are true:

- Unicode version, source URLs, file hashes, and licenses are pinned.
- Re-running the generator produces no source diff.
- NFD/NFC pass every applicable case in `NormalizationTest.txt`.
- grapheme segmentation passes every applicable case in `GraphemeBreakTest.txt`.
- public API behavior, allocation notes, target matrix, and known limitations
  are documented.
- native, wasm, wasm-gc, and js outcomes are reported separately. A missing
  runner is an explicit release gate, not an implicit pass.

## Non-Goals for Agents

- Do not optimize table compression before there is a correct baseline and a
  measured size problem.
- Do not introduce runtime downloads or a platform-specific correctness path.
- Do not alter the pinned Unicode version within an implementation task.
- Do not claim full Unicode support from this MVP.

## Milestones

| Milestone | Deliverable | Required proof |
|---|---|---|
| M0 | Project skeleton and CI contract | U-00 commands pass |
| M1 | Deterministic Unicode data generation | source manifest + no-diff generation |
| M2 | NFD/NFC | full normalization conformance |
| M3 | Extended grapheme clusters | full grapheme conformance |
| M4 | Release evidence | target matrix and benchmarks |
