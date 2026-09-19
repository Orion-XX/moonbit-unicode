# MoonBit Unicode Project Agent Guide

This repository is preparing a production-quality MoonBit Unicode text library.
Read `docs/research/MOONBIT_PROJECT_SPIKES.md` before making architectural
changes. The project is intentionally narrower than ICU.

## Scope

The first release supports only:

- Unicode 16.0 data, pinned in the repository;
- UTF-8 `String` inputs using MoonBit core's existing decoding semantics;
- canonical normalization: NFD and NFC;
- UAX #29 extended grapheme cluster segmentation;
- native, wasm, wasm-gc, and JavaScript test targets when the relevant runner
  is available.

Do not add NFKC/NFKD, case folding, word/line breaking, collation, bidi,
confusable detection, locale behavior, or a new UTF-8 decoder unless an
explicit task expands the scope.

## Existing MoonBit Boundaries

Do not duplicate `moonbitlang/core` UTF-8 decoding, `Char`, or Unicode scalar
iteration APIs. `String::iter` operates on Unicode scalars, not grapheme
clusters. Build normalization and segmentation on top of core behavior.

Use `moonbitlang/core/quickcheck` for property tests. Do not create another
general-purpose generator, shrinker, or random-number framework.

## Repository Layout

Keep generated data, the generator, runtime code, and conformance fixtures
separate. The intended layout is:

```text
tools/unicode-gen/       Offline Unicode data parser and code generator
unicode/data/            Version-pinned upstream source data and manifest
src/normalization/       NFD/NFC runtime implementation
src/grapheme/            UAX #29 runtime implementation
tests/conformance/       Generated/converted standard-vector tests
tests/property/          Property and regression tests
bench/                   Reproducible benchmarks
docs/                    Public design, data, and compatibility documentation
```

Generated source must include the Unicode version, source file names, and the
generator command. Never hand-edit generated tables. Fix the generator and
regenerate instead.

## Unicode Data Rules

- Pin every upstream Unicode file by version and checksum in a manifest.
- Record the Unicode data license and copyright notice.
- Generator output must be deterministic: rerunning it with unchanged inputs
  must produce no diff.
- Use the Hangul algorithms from UAX #15; do not emit unnecessary per-syllable
  decomposition/composition entries.
- Keep canonical decomposition data separate from compatibility data.
- Include only properties required for the approved API surface.

## API and Correctness Rules

- Public APIs must document Unicode version, normalization form, allocation
  behavior, and invalid UTF-8 behavior.
- NFC/NFD must preserve canonical-equivalence semantics; do not use ad hoc
  replacement maps.
- Grapheme segmentation must implement the UAX #29 extended grapheme-cluster
  rules required by the pinned Unicode version, including emoji ZWJ and
  Regional Indicator behavior.
- Resource limits and behavior on extremely long input must be explicit.
- Keep APIs target-neutral. Do not delegate correctness to JavaScript
  `Intl.Segmenter` or a platform normalization API in only one backend.

## Required Evidence Per Task

Every implementation task must add or update focused tests and report the
commands actually run. At minimum run:

```powershell
moon info
moon fmt
moon test
```

For changes to public APIs, inspect generated `.mbti` diffs. For generated
tables, run the generator's deterministic-output check. For algorithm changes,
run the relevant official conformance subset as well as local unit tests.

Before claiming a release-ready normalization implementation, run all applicable
cases from `NormalizationTest.txt`. Before claiming release-ready grapheme
segmentation, run all applicable cases from `GraphemeBreakTest.txt`.

Test all supported targets individually. If a target cannot run locally,
report it as unverified; do not infer success from native results.

## Test Requirements

- Use official Unicode vectors as the primary correctness oracle.
- Add regression tests for every fixed conformance failure.
- Include malformed UTF-8, empty strings, combining-mark runs, Hangul,
  emoji ZWJ sequences, and Regional Indicator cases where relevant.
- Add property tests where meaningful: NFD/NFC idempotence and canonical
  equivalence round trips are required once the APIs exist.
- Use a fixed seed for a regression property test and record it in a comment
  when it protects a previously found failure.
- Do not update snapshots or expected vectors merely to make a test pass;
  explain and validate every expected-output change.

## Task Discipline

- Read the assigned task document and its dependencies before editing.
- Keep one task focused on one concern: data parsing, generation, canonical
  decomposition, ordering, composition, grapheme rules, conformance import,
  benchmarks, or documentation.
- Do not refactor unrelated packages or change toolchain versions.
- Do not add network downloads to runtime code or normal test execution.
- Do not silently weaken conformance tests, skip vectors, or add broad
  exceptions. Any intentional exclusion requires a documented reason and a
  tracked follow-up.
- Do not claim a component-model, ICU, or full-Unicode implementation from
  this repository's limited scope.

## MoonBit Conventions

- Each package has `moon.pkg`; use `_test.mbt` for blackbox and `_wbtest.mbt`
  for whitebox tests.
- Keep MoonBit blocks separated with `///|`.
- Run `moon info` and `moon fmt` after changes.
- Prefer stable assertions (`assert_eq`, `assert_true`) over broad snapshots.
- Use `debug_inspect` only for structured debugging output.

## Completion Report

Every task handoff must state:

1. Files changed and generated files regenerated.
2. Unicode version and upstream data files involved.
3. Tests and targets actually run, including exact commands.
4. Conformance counts or the precise subset exercised.
5. Known failures, skipped targets, and remaining risks.

## GitHub and Project Management

The canonical repository is:

```text
https://github.com/Orion-XX/moonbit-unicode.git
```

### Work Tracking

- Use the task IDs in `docs/development/04_TASK_BREAKDOWN.md` as the unit of
  work. Do not create vague tasks such as “finish Unicode”.
- Track each task as an Issue or project item with its task ID, dependencies,
  acceptance criteria, and current status.
- Keep the dependency order visible. A task blocked by an incomplete
  prerequisite stays blocked; do not silently implement prerequisite work in a
  downstream task.
- Use a small Kanban flow: `Backlog` → `Ready` → `In progress` → `Review` →
  `Done`, with `Blocked` called out explicitly when needed.
- One coding window owns one task at a time. Parallel tasks must have distinct
  allowed paths or isolated branches/worktrees. Shared-file conflicts are
  resolved by the task owner or maintainer, never by overwriting another
  window's changes.
- Keep issue, branch, commit, and pull-request descriptions linked by the same
  task ID, for example `U-03`.

### Branches and Commits

- Keep the default branch release-ready. Do not commit experimental or
  half-verified work directly to it.
- Use short task branches such as `u03-normalization-tables` or
  `u10-grapheme-segmentation`. Do not reuse a branch for unrelated tasks.
- Make commits small and coherent: one logical change, its focused tests, and
  required generated output. Do not mix formatting-only churn or unrelated
  refactors into an implementation commit.
- Prefer a simple Conventional Commit subject with the task ID, for example:
  `feat(normalization): generate canonical tables (U-03)` or
  `test(grapheme): import UAX 29 vectors (U-11)`.
- Commit messages must describe intent, not merely files changed. Mention
  regenerated data or an intentional compatibility decision when relevant.
- Never commit secrets, local caches, downloaded temporary archives, build
  outputs, or unreviewed generated-table edits. Generated tables belong in a
  commit only when produced by the pinned generator and accompanied by its
  provenance.
- Do not rewrite shared history, force-push, reset other agents' work, or use
  destructive cleanup commands. If history needs cleanup, ask the maintainer.

### Pull Requests and Review

- Every non-trivial task lands through a pull request, unless the maintainer
  explicitly approves a direct documentation-only commit.
- A pull request title starts with its task ID and states the outcome, for
  example `U-07: publish NFC/NFD APIs`.
- The pull request body must include scope, linked Issue, files changed,
  commands and results, target matrix, conformance counts, known failures,
  and remaining risks. Copy the task handoff report; do not replace evidence
  with a claim such as “tests pass”.
- Reviewers check task boundaries, generated-data provenance, official-vector
  coverage, API compatibility, and whether unverified targets are honestly
  marked. A native pass does not approve wasm, wasm-gc, or js claims.
- Do not merge while required CI is failing or unverified without an explicit
  maintainer decision recorded in the Issue/PR. Follow-up waivers must name
  the missing evidence and an owner.

### Releases and Maintenance

- Release notes must identify the Unicode data version, MoonBit/toolchain
  version, supported targets, conformance totals, benchmark artifact, and
  known limitations.
- Tag releases only from the default branch after U-14's checklist is complete.
- Unicode data updates are maintenance projects, not incidental dependency
  bumps: open a dedicated task, update hashes and licenses, regenerate all
  tables and fixtures, rerun the full conformance matrix, and document any
  behavioral changes.
