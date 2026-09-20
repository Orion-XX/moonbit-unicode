# U-08 handoff: normalization conformance

U-08 imports every applicable row from Unicode 16.0.0 `NormalizationTest.txt`
without changing the normalization implementation. The importer preserves the
source line and all five scalar columns in a deterministic generated fixture.
The conformance test checks NFC and NFD for columns 1 through 4 against the
standard's NFC (column 2) and NFD (column 3) outputs, with code-point-oriented
diagnostics.

The pinned input is `unicode/data/16.0.0/NormalizationTest.txt`, SHA-256
`d811971453e7075e1ad56fb1b301eece5aa80757b81f6156e74a1bfb3ae5ceb1`.

Commands and results are recorded in the task handoff. The generated fixture
is `tests/conformance/generated_normalization_cases.mbt`; rerunning import and
check with unchanged input must produce no diff.
