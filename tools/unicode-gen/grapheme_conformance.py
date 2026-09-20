"""Import and verify Unicode 16.0.0 extended grapheme vectors."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_DATA = ROOT / "unicode" / "data" / "16.0.0"
DEFAULT_OUTPUT = ROOT / "tests" / "conformance" / "generated_grapheme_cases.mbt"


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


def parse(path: Path) -> list[tuple[int, list[int], list[int], str]]:
    vectors = []
    for line_number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        body = raw.split("#", 1)[0].strip()
        if not body:
            continue
        tokens = body.split()
        if not tokens or tokens[0] != "÷" or tokens[-1] != "÷":
            raise ValueError(f"{path.name}:{line_number}: vector must start and end with ÷")
        code_points = []
        breaks = [0]
        for token in tokens:
            if token == "÷":
                if breaks[-1] != len(code_points):
                    breaks.append(len(code_points))
            elif token == "×":
                continue
            else:
                code_points.append(scalar(token, path.name, line_number))
        if breaks[-1] != len(code_points):
            raise ValueError(f"{path.name}:{line_number}: missing terminal break")
        encoded_syntax = body.replace("÷", "D").replace("×", "X")
        vectors.append((line_number, code_points, breaks, encoded_syntax))
    return vectors


def moon_array(values: list[int]) -> str:
    return "[" + ", ".join(str(value) for value in values) + "]"


def emit(data_dir: Path) -> str:
    source = data_dir / "auxiliary" / "GraphemeBreakTest.txt"
    vectors = parse(source)
    lines = [
        "// GENERATED FILE - DO NOT EDIT.",
        "// Unicode version: 16.0.0",
        f"// Input: auxiliary/GraphemeBreakTest.txt SHA-256: {digest(source)}",
        "// Generator: tools/unicode-gen/grapheme_conformance.py",
        "// Command: python tools/unicode-gen/grapheme_conformance.py --import-tests --data unicode/data/16.0.0",
        "// Each row is source line | scalar code points | scalar break indexes | source syntax (D=break, X=no-break).",
        "",
        "///|",
        "pub let grapheme_cases : Array[String] = [",
    ]
    for line_number, code_points, breaks, source_syntax in vectors:
        fields = [
            str(line_number),
            " ".join(f"{value:X}" for value in code_points),
            " ".join(str(value) for value in breaks),
            source_syntax,
        ]
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
        print(f"imported {len(parse(args.data.resolve() / 'auxiliary' / 'GraphemeBreakTest.txt'))} vectors: {output}")


if __name__ == "__main__":
    main()
