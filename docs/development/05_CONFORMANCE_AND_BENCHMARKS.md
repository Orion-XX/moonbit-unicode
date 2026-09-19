# Conformance and Benchmark Evidence

## Normative Inputs

The first release is pinned to Unicode 16.0.0. The primary correctness inputs
are the official files, checked into `unicode/data/16.0.0/` with hashes from
the manifest:

| Capability | Input | Upstream source |
|---|---|---|
| NFC/NFD | `NormalizationTest.txt` | <https://www.unicode.org/Public/16.0.0/ucd/NormalizationTest.txt> |
| Extended grapheme clusters | `auxiliary/GraphemeBreakTest.txt` | <https://www.unicode.org/Public/16.0.0/ucd/auxiliary/GraphemeBreakTest.txt> |

Algorithm interpretation is constrained by [UAX #15](https://www.unicode.org/reports/tr15/)
and [UAX #29](https://www.unicode.org/reports/tr29/), using the revisions
applicable to Unicode 16.0.0. These files, not rendered text or an installed
platform library, are the release oracle.

## Harness Rules

The generator imports vectors deterministically from checked-in inputs. Each
generated case retains upstream filename and line number, even when comments or
blank lines are omitted from executable output.

Normalization cases must retain the input and all expected scalar sequences
needed to test UAX #15's normal-form relations. Grapheme cases must retain the
original `÷` and `×` decisions and derive expected *byte* ranges only after
encoding the scalar sequence as MoonBit `String`.

On failure, report all of the following:

- Unicode filename and source line;
- target (`native`, `wasm`, `wasm-gc`, or `js`);
- input code points;
- expected and actual code points for normalization, or expected and actual
  boundary ranges plus scalar boundaries for segmentation;
- the exact public API under test.

Never skip, rewrite, sample, or weaken an official vector to achieve a passing
result. A truly inapplicable case must be listed with source line and technical
reason; for this NFC/NFD and extended-grapheme scope, the expected release count
is zero inapplicable cases.

## Verification Commands

U-00 owns exact package-specific conformance test selectors. The following
commands are the required release sequence; replace only the two explicit
`<...>` selectors once U-00 establishes them, then keep the documented form
stable.

```powershell
moon info
moon fmt
moon run tools/unicode-gen -- check --data unicode/data/16.0.0
moon test
moon test <normalization-conformance-selector>
moon test <grapheme-conformance-selector>
moon test --target native
moon test --target wasm
moon test --target wasm-gc
moon test --target js
```

Run the generator check before tests so a stale table or stale imported fixture
cannot produce a misleading pass. If any command is unsupported by the pinned
MoonBit version, record the exact command, diagnostic, toolchain version, and
target as **unverified**. It is neither a pass nor a waived requirement.

## Target Result Matrix

Record a table like this for every release candidate and CI run that changes
runtime code, generated tables, or toolchain version:

| Target | Runner/version | Generator check | Unit/property | Normalization vectors | Grapheme vectors | Status/issue |
|---|---|---|---|---|---|---|
| native | | | | | | |
| wasm | | | | | | |
| wasm-gc | | | | | | |
| js | | | | | | |

Use `pass`, `fail`, or `unverified` only. `unverified` must include why the
runner was unavailable and where the setup work is tracked. Do not copy native
results into another row.

## Benchmark Preconditions and Policy

Benchmark only after U-08 and U-11 report complete conformance passes. Runtime
benchmarks exercise the MoonBit implementation itself. It must not call Node
ICU, JavaScript `Intl`, a host normalization API, or another platform segmenter
to obtain the measured answer.

A local differential tool or optional comparison against a reference
implementation is allowed only when clearly marked non-normative. It cannot
replace official vector testing, alter expected outputs, or be reported as the
library's runtime throughput.

## Required Benchmark Corpus

Build fixtures from explicit scalar sequences and report their generation
method/version. Include each category below at small and repeated realistic
sizes where practical:

| Corpus | Why it is required |
|---|---|
| ASCII | fast-path and byte-offset baseline |
| Latin composed/decomposed | canonical mapping and combining order |
| long combining-mark runs | ordering, blocking, and allocation pressure |
| Hangul | algorithmic decomposition/composition |
| emoji ZWJ | GB11 state retention |
| Regional Indicators | GB12/GB13 parity state |
| mixed multilingual prose | representative mixed-script behavior |

For each corpus run NFD, NFC, and grapheme-boundary measurement as applicable.
Report input byte count, output byte count for normalizers, wall time,
throughput in MB/s, iteration/repeat count, and summary statistic (median is
preferred). Report generated source size for each table file and total table
source size. Record peak or allocated memory only when the target tool exposes
it reliably; otherwise state `unavailable` rather than estimating it.

Every benchmark record includes: MoonBit `moon info` output or relevant version
fields, target runner/version, operating system/CPU, build mode/flags, corpus
identifier, warm-up behavior, repeat count, and raw or summarized timing data.
Use the same corpus and repeat policy for before/after comparisons.

## Release Evidence Checklist

- Manifest has Unicode 16.0.0 URLs, hashes, and license notice.
- `unicode-gen check` passes with no generated-file diff.
- All normalization vectors pass, with total/passed/failed/skipped counts.
- All grapheme vectors pass, with total/passed/failed/skipped counts.
- Property and regression tests identify their fixed seeds and minimized cases.
- Native, wasm, wasm-gc, and js matrix rows state pass, fail, or unverified.
- Benchmarks include every required corpus category and table-size measurement.
- Public documentation describes Unicode version, API semantics, invalid-input
  inheritance, allocation behavior, and excluded functionality.
- Any failed or unverified target, toolchain limitation, or known performance
  risk is visible in release notes; none is represented as a pass.
