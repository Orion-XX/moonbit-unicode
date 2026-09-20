"""Import and verify Unicode 16.0 normalization conformance vectors."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATA = ROOT / "unicode" / "data" / "16.0.0"
DEFAULT_OUTPUT = ROOT / "tests" / "conformance" / "generated_normalization_cases.mbt"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def scalar(token: str, filename: str, line: int) -> int:
    try:
        value = int(token, 16)
    except ValueError as exc:
        raise ValueError(f"{filename}:{line}: invalid code point {token!r}") from exc
    if value > 0x10FFFF or 0xD800 <= value <= 0xDFFF:
        raise ValueError(f"{filename}:{line}: non-scalar code point {token!r}")
    return value


def parse(path: Path) -> list[tuple[int, list[list[int]]]]:
    vectors = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        body = raw.split("#", 1)[0].strip()
        if not body or body.startswith("@"):
            continue
        columns = [column.strip() for column in body.split(";")]
        if columns and columns[-1] == "":
            columns.pop()
        if len(columns) != 5:
            raise ValueError(f"{path.name}:{line_number}: expected five columns")
        parsed = []
        for column in columns:
            parsed.append(
                [scalar(token, path.name, line_number) for token in column.split()]
            )
        vectors.append((line_number, parsed))
    return vectors


def moon_array(values: list[int]) -> str:
    return "[" + ", ".join(str(value) for value in values) + "]"


def emit(data_dir: Path) -> str:
    source = data_dir / "NormalizationTest.txt"
    vectors = parse(source)
    lines = [
        "// GENERATED FILE - DO NOT EDIT.",
        "// Unicode version: 16.0.0",
        f"// Input: NormalizationTest.txt SHA-256: {digest(source)}",
        "// Generator: tools/unicode-gen/normalization_conformance.py",
        "// Command: python tools/unicode-gen/normalization_conformance.py --import-tests --data unicode/data/16.0.0",
        "",
        "///|",
        "pub let normalization_cases : Array[String] = [",
    ]
    for line_number, columns in vectors:
        fields = [str(line_number)] + [" ".join(f"{value:X}" for value in column) for column in columns]
        lines.append("  \"" + "|".join(fields) + "\",")
    lines.extend(["]", ""])
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=Path, default=DEFAULT_DATA)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--import-tests", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.import_tests == args.check:
        parser.error("choose exactly one of --import-tests or --check")
    generated = emit(args.data.resolve())
    output = args.output.resolve()
    if args.check:
        if not output.exists() or output.read_text(encoding="ascii") != generated:
            raise SystemExit(f"generated output differs: {output}")
        print(f"deterministic output verified: {output}")
    else:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(generated, encoding="ascii", newline="\n")
        print(f"imported {len(parse(args.data.resolve() / 'NormalizationTest.txt'))} vectors: {output}")


if __name__ == "__main__":
    main()
