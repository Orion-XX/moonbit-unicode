"""Focused U-09 validation tests for the offline grapheme table generator."""
import importlib.util
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("generate_tables.py")
SPEC = importlib.util.spec_from_file_location("generate_tables", SCRIPT)
generator = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(generator)


class GraphemeGeneratorTest(unittest.TestCase):
    def test_every_required_property_is_emitted(self):
        generated, counts = generator.emit_grapheme(generator.DEFAULT_DATA)
        self.assertEqual(13, len(generator.GRAPHEME_PROPERTIES))
        self.assertGreater(counts[0], counts[1])
        self.assertGreater(counts[2], 0)
        for property_name in generator.GRAPHEME_PROPERTIES:
            self.assertIn(f"  {generator.GRAPHEME_VARIANTS[property_name]}\n", generated)

    def test_overlapping_ranges_are_rejected_without_precedence(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "property.txt"
            path.write_text("0041..0043 ; A\n0043..0044 ; B\n", encoding="ascii")
            with self.assertRaisesRegex(ValueError, r"property\.txt:2: range overlaps property\.txt:1"):
                generator.property_ranges(path, {"A", "B"})

    def test_unexpected_grapheme_property_is_not_silently_encoded(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "property.txt"
            path.write_text("0041 ; Unknown\n", encoding="ascii")
            self.assertEqual([], generator.property_ranges(path, set(generator.GRAPHEME_PROPERTIES)))


if __name__ == "__main__":
    unittest.main()
