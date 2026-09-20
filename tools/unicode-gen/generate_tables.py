"""Generate private Unicode 16.0.0 tables from the pinned local UCD files.

This is intentionally an offline generator.  It reads only the checked-in UCD
files and writes a deterministic MoonBit source file; no Unicode or host
normalization API is consulted.
"""
from __future__ import annotations

import hashlib
import re
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATA = ROOT / "unicode" / "data" / "16.0.0"
DEFAULT_OUT = ROOT / "src" / "internal" / "tables" / "normalization_data.mbt"
DEFAULT_GRAPHEME_OUT = ROOT / "src" / "internal" / "tables" / "grapheme_data.mbt"

GRAPHEME_PROPERTIES = (
    "Control",
    "CR",
    "Extend",
    "L",
    "LF",
    "LV",
    "LVT",
    "Prepend",
    "Regional_Indicator",
    "SpacingMark",
    "T",
    "V",
    "ZWJ",
)

GRAPHEME_VARIANTS = {
    "Control": "Control",
    "CR": "CR",
    "Extend": "Extend",
    "L": "L",
    "LF": "LF",
    "LV": "LV",
    "LVT": "LVT",
    "Prepend": "Prepend",
    "Regional_Indicator": "RegionalIndicator",
    "SpacingMark": "SpacingMark",
    "T": "T",
    "V": "V",
    "ZWJ": "ZWJ",
}


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


def property_ranges(path: Path, expected: set[str] | None = None):
    """Parse and validate non-overlapping UCD property ranges.

    The UCD property files can contain unrelated properties.  Callers filter
    those before validation so that only the generated property domain is
    accepted.  Any overlap is rejected: U-09 intentionally has no implicit
    precedence rule that could hide a changed upstream data assignment.
    """
    result = []
    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        fields = [field.strip() for field in line.split(";")]
        if len(fields) != 2:
            raise ValueError(f"{path.name}:{line_no}: expected range ; property")
        value = fields[1]
        if expected is not None and value not in expected:
            continue
        pieces = fields[0].split("..")
        if len(pieces) not in (1, 2):
            raise ValueError(f"{path.name}:{line_no}: invalid code point range")
        lo, hi = int(pieces[0], 16), int(pieces[-1], 16)
        if lo > hi:
            raise ValueError(f"{path.name}:{line_no}: range start exceeds end")
        result.append((lo, hi, value, line_no))
    result.sort()
    for previous, current in zip(result, result[1:]):
        if current[0] <= previous[1]:
            raise ValueError(
                f"{path.name}:{current[3]}: range overlaps {path.name}:{previous[3]}"
            )
    return result


def merge_property_ranges(records):
    merged = []
    for lo, hi, value, _ in records:
        if merged and merged[-1][1] + 1 == lo and merged[-1][2] == value:
            merged[-1] = (merged[-1][0], hi, value)
        else:
            merged.append((lo, hi, value))
    return merged


def array(values):
    return "[" + ", ".join(str(v) for v in values) + "]"


def emit(records, data_dir: Path):
    canonical, compatibility, ccc, excluded = records
    lines = [
        "// GENERATED FILE - DO NOT EDIT.",
        "// Unicode version: 16.0.0",
        f"// Input: UnicodeData.txt SHA-256: {digest(data_dir / 'UnicodeData.txt')}",
        f"// Input: CompositionExclusions.txt SHA-256: {digest(data_dir / 'CompositionExclusions.txt')}",
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


def emit_grapheme(data_dir: Path):
    grapheme_input = data_dir / "GraphemeBreakProperty.txt"
    emoji_input = data_dir / "emoji-data.txt"
    grapheme = property_ranges(grapheme_input, set(GRAPHEME_PROPERTIES))
    found = {value for _, _, value, _ in grapheme}
    missing = set(GRAPHEME_PROPERTIES) - found
    if missing:
        raise ValueError(f"{grapheme_input.name}: missing required properties: {sorted(missing)}")
    extended = property_ranges(emoji_input, {"Extended_Pictographic"})
    compact_grapheme = merge_property_ranges(grapheme)
    compact_extended = merge_property_ranges(extended)
    lines = [
        "// GENERATED FILE - DO NOT EDIT.",
        "// Unicode version: 16.0.0",
        f"// Input: GraphemeBreakProperty.txt SHA-256: {digest(grapheme_input)}",
        f"// Input: emoji-data.txt SHA-256: {digest(emoji_input)}",
        "// Generator: tools/unicode-gen/generate_tables.py",
        "// Command: python tools/unicode-gen/generate_tables.py grapheme --data unicode/data/16.0.0",
        f"// Grapheme property ranges: {len(grapheme)} source, {len(compact_grapheme)} encoded.",
        f"// Extended_Pictographic ranges: {len(extended)} source, {len(compact_extended)} encoded.",
        "",
        "///|",
        "pub enum GraphemeBreakProperty {",
        "  Other",
    ]
    lines += [f"  {GRAPHEME_VARIANTS[value]}" for value in GRAPHEME_PROPERTIES]
    lines += [
        "}",
        "",
        "///|",
        "pub struct GraphemeBreakRange {",
        "  start : Int",
        "  end : Int",
        "  property : GraphemeBreakProperty",
        "}",
        "",
        "///|",
        "pub let grapheme_break_ranges : Array[GraphemeBreakRange] = [",
    ]
    lines += [
        f"  {{ start: {lo}, end: {hi}, property: {GRAPHEME_VARIANTS[value]} }},"
        for lo, hi, value in compact_grapheme
    ]
    lines += [
        "]",
        "",
        "///|",
        "pub struct ExtendedPictographicRange {",
        "  start : Int",
        "  end : Int",
        "}",
        "",
        "///|",
        "pub let extended_pictographic_ranges : Array[ExtendedPictographicRange] = [",
    ]
    lines += [f"  {{ start: {lo}, end: {hi} }}," for lo, hi, _ in compact_extended]
    lines += ["]", ""]
    return "\n".join(lines), (len(grapheme), len(compact_grapheme), len(extended), len(compact_extended))


def render_checked(output: Path, generated: str, check: bool):
    if check:
        current = output.read_text(encoding="ascii")
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="ascii", newline="\n", suffix=".mbt", dir=output.parent, delete=False
        ) as temporary:
            temporary.write(generated)
            temporary_path = Path(temporary.name)
        try:
            formatted = temporary_path.read_text(encoding="ascii")
        finally:
            temporary_path.unlink(missing_ok=True)
        if current != formatted:
            raise SystemExit(f"generated output differs: {output}")
        print(f"deterministic output verified: {output}")
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(generated, encoding="ascii", newline="\n")
        print(f"generated: {output}")


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("table", choices=("normalization", "grapheme", "all"), nargs="?", default="all")
    parser.add_argument(
        "--data",
        type=Path,
        default=DEFAULT_DATA,
        help="Unicode 16.0.0 data directory",
    )
    parser.add_argument("--output", type=Path, help="generated MoonBit source path (one table only)")
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the committed table is identical without rewriting it",
    )
    args = parser.parse_args()
    data_dir = args.data.resolve()
    if args.output and args.table == "all":
        parser.error("--output requires normalization or grapheme")
    if args.table in ("normalization", "all"):
        output = (args.output or DEFAULT_OUT).resolve()
        generated = emit(
            (*unicode_data(data_dir / "UnicodeData.txt"), exclusions(data_dir / "CompositionExclusions.txt")),
            data_dir,
        )
        render_checked(output, generated, args.check)
    if args.table in ("grapheme", "all"):
        output = (args.output or DEFAULT_GRAPHEME_OUT).resolve()
        generated, counts = emit_grapheme(data_dir)
        render_checked(output, generated, args.check)
        print(
            "grapheme ranges: "
            f"{counts[0]} source/{counts[1]} encoded; "
            f"Extended_Pictographic: {counts[2]} source/{counts[3]} encoded"
        )


if __name__ == "__main__":
    main()
