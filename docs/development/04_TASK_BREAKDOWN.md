# AI-Assignable Task Breakdown

## Assignment Rules

Assign exactly one card at a time. An agent must read `AGENTS.md` and every
listed dependency before editing. A task may add only the files and directories
listed by its card, plus narrowly necessary package metadata and focused tests.
It must report every command actually run, including unavailable targets.

All task cards inherit the Unicode 16.0 boundary, no-runtime-network rule,
MoonBit-core ownership boundary, and deterministic-generation requirements in
`AGENTS.md`. Intended paths below do not exist until U-00 creates the project
skeleton.

## Dependency Map

```text
U-00 -> U-01 -> U-02 -> U-03 -> U-04 -> U-05 -> U-06 -> U-07 -> U-08
                     \-> U-09 -> U-10 -> U-11
U-07 + U-10 -> U-12
U-08 + U-11 -> U-13 -> U-14
```

## Common Handoff

Every card handoff must state: changed files; generated files and provenance;
exact commands and results; test/conformance count; target results; known
failures; and work deliberately left for later cards. Do not claim another
card's acceptance criteria.

## U-00: Establish the Project Skeleton

**Purpose/output.** Create the MoonBit module, package skeleton, empty test
layout, target-matrix CI contract, and documented canonical commands.

**Dependencies.** None.

**Allowed paths.** `moon.mod`, `src/`, `tools/unicode-gen/`, `tests/`,
`bench/`, CI configuration, and `docs/development/` command references.

**Requirements.** Create packages matching `01_ARCHITECTURE.md`; make each
package compile with a minimal public placeholder only where needed. Establish
the commands promised by `02_DATA_PIPELINE.md`. Configure CI to report native,
wasm, wasm-gc, and js independently, never treating an unavailable runner as a
pass.

**Required commands.** `moon info`; `moon fmt`; `moon test`; `moon test
--target native`; `moon test --target wasm`; `moon test --target wasm-gc`;
`moon test --target js`.

**Acceptance.** Native baseline passes. Each other target has either a passing
baseline or an explicit runner/setup failure recorded in CI and the handoff.
`moon run tools/unicode-gen -- check --data unicode/data/16.0.0` has a defined,
failing-if-data-is-missing behavior rather than a silent success.

**Non-goals/prohibitions.** No Unicode algorithms, generated data, downloaded
data, public normalization API, or fake conformance pass.

**Handoff.** Include the created package tree, canonical command forms, and one
matrix row per target with the exact pass/fail/unverified reason.

## U-01: Pin Unicode Inputs

**Purpose/output.** Add a reproducible Unicode 16.0.0 source-data manifest and
maintenance procedure.

**Dependencies.** U-00.

**Allowed paths.** `unicode/data/16.0.0/`, `docs/development/`, generator
metadata/tests under `tools/unicode-gen/`.

**Requirements.** Add every file listed in `02_DATA_PIPELINE.md`, source URL,
SHA-256, version, license/copyright notice, and a PowerShell-compatible
maintenance command or script. The normal generator consumes only checked-in
local inputs. Verify hashes before parsing.

**Required commands.** `moon info`; manifest/hash verification command;
`moon run tools/unicode-gen -- check --data unicode/data/16.0.0`.

**Acceptance.** A modified input or manifest hash makes verification fail with
the filename; all required Unicode 16.0.0 inputs verify successfully.

**Non-goals/prohibitions.** No unpinned latest-UCD download, network work in
tests, hand-maintained mappings, or Unicode-version upgrade.

**Handoff.** Include the manifest path, verified filenames/hashes, upstream
URLs, license location, and one demonstrated hash-mismatch failure.

## U-02: Parse UCD into an Intermediate Model

**Purpose/output.** Parse the pinned data into typed, validated generator
records for normalization and grapheme generation.

**Dependencies.** U-01.

**Allowed paths.** `tools/unicode-gen/`, parser fixtures under
`tools/unicode-gen/`, and generator documentation.

**Requirements.** Parse semicolon/property formats, code-point ranges,
canonical decomposition mappings, CCC, composition exclusions, grapheme-break
properties, Extended_Pictographic, and conformance-vector syntax. Preserve
input filename and line number. Reject malformed scalars, overlapping or
conflicting ranges, duplicate contradictory records, missing required fields,
and manifest mismatch.

**Required commands.** `moon fmt`; parser unit tests; generator `check` on
the pinned data.

**Acceptance.** Small fixtures demonstrate all required record kinds and each
failure class reports filename plus source line. No runtime package imports the
parser.

**Non-goals/prohibitions.** No generated MoonBit tables, normalization logic,
grapheme state machine, or compatibility-normalization API.

**Handoff.** Include parsed record counts by source file and the fixture/test
names that prove each required parser error reports a source line.

## U-03: Generate Normalization Tables

**Purpose/output.** Generate deterministic private tables for canonical
decomposition, CCC, composition pairs, and exclusions.

**Dependencies.** U-02.

**Allowed paths.** `tools/unicode-gen/`, `src/internal/tables/`,
`tests/conformance/generated_normalization_cases.mbt`, generator tests.

**Requirements.** Generate stable sorted/range-encoded source with the header
defined in `02_DATA_PIPELINE.md`. Exclude algorithmic Hangul syllables from
per-syllable tables. Model compatibility data only to avoid incorrectly using
it, not to publish NFK behavior. Add deterministic-output checking.

**Required commands.** `moon fmt`; `moon run tools/unicode-gen -- generate
--data unicode/data/16.0.0`; `moon run tools/unicode-gen -- check --data
unicode/data/16.0.0`; `moon test`.

**Acceptance.** A second generation produces no diff; tables compile; focused
fixtures prove canonical and compatibility mappings are distinguished.

**Non-goals/prohibitions.** No hand-edited generated table, no 11,172-entry
Hangul table, and no public API.

**Handoff.** Include generated paths and sizes, input hashes, the no-diff check
result, and a note confirming algorithmic Hangul exclusion.

## U-04: Canonical Decomposition and Hangul

**Purpose/output.** Implement recursive canonical decomposition and algorithmic
Hangul decomposition as an internal stage.

**Dependencies.** U-03.

**Allowed paths.** `src/normalization/`, its package metadata and focused
whitebox tests.

**Requirements.** Lookup only canonical mappings, recurse until stable, and
apply the UAX #15 Hangul constants/algorithm. Test Latin precomposed examples,
multi-step mappings, Hangul LV/LVT, unassigned scalars, and empty input.

**Required commands.** `moon fmt`; normalization focused tests; `moon test`;
`moon test --target native`.

**Acceptance.** Stage tests demonstrate decomposition without reordering and
prove compatibility mappings are untouched.

**Non-goals/prohibitions.** No canonical ordering, composition, exported NFC or
NFD function, or host normalization API.

**Handoff.** Include the internal entry point, mappings exercised, Hangul cases,
and focused test commands/results.

## U-05: Canonical Ordering

**Purpose/output.** Add the CCC reordering stage for decomposed scalar runs.

**Dependencies.** U-04.

**Allowed paths.** `src/normalization/` and focused tests only.

**Requirements.** Reorder non-starters by canonical combining class within the
correct starter boundaries while retaining stable order for equal CCC. Cover
leading non-starters, long runs, equal classes, and new starters.

**Required commands.** `moon fmt`; focused tests; `moon test`; `moon test
--target native`.

**Acceptance.** Tests expose both a reorder-required sequence and a
no-reorder sequence; output has no change across starter boundaries.

**Non-goals/prohibitions.** No composition or public API; do not sort by code
point as a surrogate for CCC.

**Handoff.** Include the tested CCC sequences, stable-equal-CCC evidence, long
run coverage, and focused test commands/results.

## U-06: Canonical Composition

**Purpose/output.** Add NFC composition, canonical blocking, exclusions, and
algorithmic Hangul composition.

**Dependencies.** U-05.

**Allowed paths.** `src/normalization/` and focused tests only.

**Requirements.** Compose NFD output using generated pair data; implement
blocking based on CCC, composition exclusions, and L+V / LV+T Hangul rules.
Test a blocked pair, excluded pair, Latin composition, and both Hangul steps.

**Required commands.** `moon fmt`; focused tests; `moon test`; `moon test
--target native`.

**Acceptance.** The internal pipeline produces correct targeted NFC output and
does not compose compatibility-only pairs.

**Non-goals/prohibitions.** No NFKC/NFKD, public API naming decision, or
conformance-vector import.

**Handoff.** Include cases for blocking, exclusions, Latin and Hangul
composition, plus focused test commands/results.

## U-07: Publish NFC/NFD APIs

**Purpose/output.** Expose the small `nfd` and `nfc` public API over the tested
internal pipeline.

**Dependencies.** U-06.

**Allowed paths.** `src/normalization/`, package metadata, API documentation,
and blackbox tests.

**Requirements.** Match `03_API_AND_TEST_CONTRACT.md`, document Unicode
version/allocation/invalid-input inheritance, and test empty and ASCII fast
paths without changing semantics.

**Required commands.** `moon info`; `moon fmt`; `moon test`; all four target
commands from U-00; inspect generated `.mbti` changes.

**Acceptance.** Public tests prove NFD/NFC idempotence on targeted values;
public API has no data-table exposure; target outcomes are individually
reported.

**Non-goals/prohibitions.** No NFK APIs, byte-buffer API, host fallback, or
claim of full conformance before U-08.

**Handoff.** Include the `.mbti` API delta, allocation/invalid-input docs, and
the result for every target without inferring cross-target success.

## U-08: Run Normalization Conformance

**Purpose/output.** Import and execute every applicable Unicode 16.0
`NormalizationTest.txt` vector against public APIs.

**Dependencies.** U-07.

**Allowed paths.** `tools/unicode-gen/`, `tests/conformance/`, generated test
fixtures, and conformance documentation.

**Requirements.** Preserve upstream line identifiers and five-column inputs;
test required UAX #15 relations for NFC and NFD; provide code-point-oriented
failure reports as specified in `03_API_AND_TEST_CONTRACT.md`.

**Required commands.** generator `import-tests` and `check`; conformance-only
test command; `moon test`; all available U-00 target commands.

**Acceptance.** Report total/passed/failed/skipped counts. Every applicable
vector passes; any truly inapplicable vector is documented with source line and
reason, with expected default of zero exclusions.

**Non-goals/prohibitions.** No filtering failed cases, expected-output edits,
or performance optimization.

**Handoff.** Include the upstream file hash, import command, total/passed/
failed/skipped counts per target, and full diagnostics for every non-pass.

## U-09: Generate Grapheme Property Tables

**Purpose/output.** Generate deterministic private lookup tables for grapheme
break properties and Extended_Pictographic.

**Dependencies.** U-02.

**Allowed paths.** `tools/unicode-gen/`, `src/internal/tables/`,
`tests/conformance/generated_grapheme_cases.mbt`, and generator tests.

**Requirements.** Parse and encode every required UAX #29 property range,
validate range precedence/conflicts, and emit a compact measured baseline with
the required provenance header.

**Required commands.** `moon fmt`; generator `generate`; generator `check`;
`moon test`.

**Acceptance.** Re-generation is no-diff; representative scalars cover every
property used by the state machine; generated source compiles on native.

**Non-goals/prohibitions.** No segmentation state machine, regex, `Intl`, or
manual property exceptions in runtime code.

**Handoff.** Include generated paths/sizes, property/range counts, input hashes,
the no-diff result, and representative lookup tests.

## U-10: Implement Extended Grapheme Boundaries

**Purpose/output.** Implement the UAX #29 extended-grapheme state machine and
publish the byte-boundary iterator API.

**Dependencies.** U-09.

**Allowed paths.** `src/grapheme/`, its package metadata/API documentation,
and focused tests.

**Requirements.** Select and document the exact iterator representation;
implement GB3--GB13 plus GB999 for Unicode 16.0, retaining GB11 emoji-ZWJ and
GB12/13 RI parity context. Return ascending end-exclusive UTF-8 byte ranges.

**Required commands.** `moon info`; `moon fmt`; focused tests; `moon test`;
all U-00 target commands; inspect `.mbti` diff.

**Acceptance.** Targeted tests cover CRLF, controls, Extend, SpacingMark,
Prepend, Hangul, emoji ZWJ, RI, empty input, and reconstruct original bytes
from ranges. No boundary splits a scalar.

**Non-goals/prohibitions.** No word/line segmentation, allocating convenience
API unless built solely atop boundaries, raw UTF-8 decoder, or platform API.

**Handoff.** Include the `.mbti` API delta, rule-to-test mapping, allocation and
lifetime contract, and individual target results.

## U-11: Run Grapheme Conformance

**Purpose/output.** Import and execute all Unicode 16.0
`auxiliary/GraphemeBreakTest.txt` vectors.

**Dependencies.** U-10.

**Allowed paths.** `tools/unicode-gen/`, `tests/conformance/`, generated
fixtures, and conformance documentation.

**Requirements.** Convert `÷`/`×` source syntax to expected byte boundaries
without losing original source line. Test the public API and emit expected vs
actual boundary/code-point reports.

**Required commands.** generator `import-tests` and `check`; grapheme
conformance test command; `moon test`; all available U-00 target commands.

**Acceptance.** Report total/passed/failed/skipped counts. Every applicable
vector passes; expected default is zero exclusions.

**Non-goals/prohibitions.** No vector skipping, rules tailored only to failing
cases, or benchmark changes.

**Handoff.** Include the upstream file hash, import command, total/passed/
failed/skipped counts per target, and complete diagnostics for every non-pass.

## U-12: Properties, Invalid Input, and Regression Replay

**Purpose/output.** Add cross-feature property tests, core-decoding inheritance
tests, and deterministic regression replay.

**Dependencies.** U-07 and U-10.

**Allowed paths.** `tests/property/`, `tests/regression/`, focused public-test
files, and documentation of test seeds.

**Requirements.** Use `moonbitlang/core/quickcheck`; test normal-form
idempotence, `nfc(nfd(x)) == nfc(x)`, range ordering/reconstruction, and
scalar-safe boundaries. Include input strings obtained via core strict/lossy
handling of malformed UTF-8 and assert only inherited semantics documented by
the project. Record fixed seeds and minimized cases for discovered failures.

**Required commands.** `moon fmt`; property/replay test command; `moon test`;
all available U-00 target commands.

**Acceptance.** Properties run deterministically under a recorded seed; a
known regression is replayable by exact test name/seed; no replacement random
or shrink framework is introduced.

**Non-goals/prohibitions.** No claim that public `String` APIs independently
validate raw invalid bytes, no unseeded flaky property test, no fuzz framework.

**Handoff.** Include property names, run counts and seeds, minimized regression
cases, strict/lossy construction evidence, and individual target results.

## U-13: Measure Tables and Runtime

**Purpose/output.** Produce reproducible size and performance evidence after
full conformance passes.

**Dependencies.** U-08 and U-11.

**Allowed paths.** `bench/`, benchmark fixtures/scripts, CI measurement setup,
and `docs/development/05_CONFORMANCE_AND_BENCHMARKS.md` results sections.

**Requirements.** Follow the datasets, metrics, target reporting, and baseline
policy in `05_CONFORMANCE_AND_BENCHMARKS.md`. Separate correctness from speed;
record hardware/toolchain and generated-table source sizes.

**Required commands.** `moon fmt`; generator `check`; benchmark command for
each runnable target; `moon test`.

**Acceptance.** Results include all required datasets and metrics, target/tool
versions, repeat policy, unavailable metrics/targets, and no semantic shortcut
or host normalization path.

**Non-goals/prohibitions.** No table compression rewrite without an approved
measured issue, no benchmark-only implementation branch, no invented memory
numbers.

**Handoff.** Include raw/summary result paths, corpus hashes, machine/toolchain
metadata, generated table sizes, repeat policy, and unavailable measurements.

## U-14: Release Documentation and Verification

**Purpose/output.** Assemble release evidence, public limits, data provenance,
and a reproducible final verification record.

**Dependencies.** U-13.

**Allowed paths.** `README.md`, `docs/`, release/CI documentation, package
metadata, and narrowly necessary verification scripts. No runtime algorithm
edits.

**Requirements.** Document supported Unicode version/APIs/targets, invalid
input inheritance, allocation behavior, source licenses, generator maintenance,
conformance totals, benchmark methodology, and unresolved limitations.

**Required commands.** Every release command in
`05_CONFORMANCE_AND_BENCHMARKS.md`, including generator check, formatter,
native test, and all runnable target tests.

**Acceptance.** Release checklist is complete with commands, results, commit or
artifact identifiers, and explicit unverified/failing targets. Claims match
evidence and stay within the first-release scope.

**Non-goals/prohibitions.** No feature expansion, Unicode version change,
silent target waiver, or retrospective alteration of conformance vectors.

**Handoff.** Include the completed release checklist, public-document paths,
exact final commands/results, conformance totals, benchmark artifact, and all
open risks or unverified targets.
