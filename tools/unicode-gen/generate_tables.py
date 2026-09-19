"""Generate the private canonical-normalization tables for Unicode 16.0.0.

This is intentionally an offline generator.  It reads only the checked-in UCD
files and writes a deterministic MoonBit source file; no Unicode or host
normalization API is consulted.
"""
from __future__ import annotations

import hashlib
import re
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "unicode" / "data" / "16.0.0"
OUT = ROOT / "src" / "internal" / "tables" / "normalization_data.mbt"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def unicode_data(path: Path):
    canonical = []
    compatibility = []
    ccc = {}
    # UCD data is ASCII-shaped, but comments in pinned files may contain
    # copyright punctuation. Decode the checked-in UTF-8 source losslessly.
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#"):
            continue
        fields = raw.split(";")
        cp = int(fields[0], 16)
        ccc[cp] = int(fields[3])
        mapping = fields[5].split()
        if not mapping:
            continue
        if mapping[0].startswith("<"):
            compatibility.append((cp, [int(x, 16) for x in mapping[1:]]))
        else:
            canonical.append((cp, [int(x, 16) for x in mapping]))
    return canonical, compatibility, ccc


def exclusions(path: Path) -> set[int]:
    result = set()
    for raw in path.read_text(encoding="utf-8").splitlines():
        value = raw.split("#", 1)[0].strip()
        if not value:
            continue
        parts = value.split("..")
        lo, hi = int(parts[0], 16), int(parts[-1], 16)
        result.update(range(lo, hi + 1))
    return result


def ranges(values: dict[int, int]):
    result = []
    for cp in sorted(values):
        value = values[cp]
        if result and result[-1][1] + 1 == cp and result[-1][2] == value:
            result[-1] = (result[-1][0], cp, value)
        else:
            result.append((cp, cp, value))
    return result


def array(values):
    return "[" + ", ".join(str(v) for v in values) + "]"


def emit(records):
    canonical, compatibility, ccc, excluded = records
    lines = [
        "// GENERATED FILE - DO NOT EDIT.",
        "// Unicode version: 16.0.0",
        f"// Input: UnicodeData.txt SHA-256: {digest(DATA / 'UnicodeData.txt')}",
        f"// Input: CompositionExclusions.txt SHA-256: {digest(DATA / 'CompositionExclusions.txt')}",
        "// Generator: tools/unicode-gen/generate_tables.py",
        "// Command: python tools/unicode-gen/generate_tables.py",
        "",
        "///|",
        "pub struct CanonicalDecomposition {",
        "  cp : Int",
        "  mapping : Array[Int]",
        "}",
        "",
        "///|",
        "pub let canonical_decompositions : Array[CanonicalDecomposition] = [",
    ]
    lines += [f"  {{ cp: {cp}, mapping: {array(mapping)} }}," for cp, mapping in canonical]
    lines += ["]", "", "///|", "pub struct CompatibilityDecomposition {", "  cp : Int", "  mapping : Array[Int]", "}", "", "///|", "pub let compatibility_decompositions : Array[CompatibilityDecomposition] = ["]
    lines += [f"  {{ cp: {cp}, mapping: {array(mapping)} }}," for cp, mapping in compatibility]
    lines += ["]", "", "///|", "pub struct CombiningClassRange {", "  start : Int", "  end : Int", "  ccc : Int", "}", "", "///|", "pub let combining_class_ranges : Array[CombiningClassRange] = ["]
    lines += [f"  {{ start: {lo}, end: {hi}, ccc: {value} }}," for lo, hi, value in ranges({cp: value for cp, value in ccc.items() if value})]
    lines += ["]", "", "///|", "pub struct CompositionPair {", "  starter : Int", "  combining : Int", "  composite : Int", "}", "", "///|", "pub let composition_pairs : Array[CompositionPair] = ["]
    pairs = sorted(
        (mapping[0], mapping[1], cp)
        for cp, mapping in canonical
        if len(mapping) == 2 and cp not in excluded
    )
    lines += [f"  {{ starter: {a}, combining: {b}, composite: {cp} }}," for a, b, cp in pairs]
    lines += ["]", "", "///|", "pub let composition_exclusions : Array[Int] = ["]
    excluded_sorted = sorted(excluded)
    for i in range(0, len(excluded_sorted), 16):
        lines.append("  " + ", ".join(str(x) for x in excluded_sorted[i : i + 16]) + ",")
    lines += ["]", ""]
    return "\n".join(lines)


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the committed table is identical without rewriting it",
    )
    args = parser.parse_args()
    generated = emit((*unicode_data(DATA / "UnicodeData.txt"), exclusions(DATA / "CompositionExclusions.txt")))
    if args.check:
        current = OUT.read_text(encoding="ascii")
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="ascii", newline="\n", suffix=".mbt", dir=OUT.parent, delete=False
        ) as temporary:
            temporary.write(generated)
            temporary_path = Path(temporary.name)
        try:
            subprocess.run(["moon", "fmt"], cwd=ROOT, check=True, capture_output=True)
            formatted = temporary_path.read_text(encoding="ascii")
        finally:
            temporary_path.unlink(missing_ok=True)
        if current != formatted:
            raise SystemExit(f"generated output differs: {OUT}")
        print(f"deterministic output verified: {OUT}")
    else:
        OUT.write_text(generated, encoding="ascii", newline="\n")
        # Keep checked-in generated source in the repository's canonical
        # MoonBit format so `--check` is a byte-for-byte comparison.
        subprocess.run(["moon", "fmt"], cwd=ROOT, check=True)
        print(f"generated: {OUT}")


if __name__ == "__main__":
    main()
