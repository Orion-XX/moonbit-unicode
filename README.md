# moonbit-unicode

Unicode 16.0 data and a target-neutral MoonBit text-library foundation.

## Current status

This repository is an early, testable project baseline. It currently ships:

- pinned Unicode 16.0 source data and checksums;
- MoonBit package boundaries for normalization, grapheme segmentation, generated tables, conformance tests, property tests, and benchmarks;
- a Unicode-data generator CLI contract that fails closed until the parser and generator features are implemented;
- CI coverage for native, wasm, wasm-gc, and JavaScript targets when their runners are available.

The public NFD/NFC and extended grapheme-cluster APIs are not implemented yet. No compatibility normalization, case folding, locale behavior, or platform-specific Unicode delegation is included.

## Development

Install the MoonBit toolchain pinned by `.github/workflows/targets.yml`, then run:

```powershell
moon info
moon fmt
moon test
```

The `unicode/data/16.0.0` directory is version-pinned input data. Generated tables must be produced by the generator and must not be hand-edited.

## License

Project source is provided under the repository license. Unicode data remains subject to the Unicode license and copyright notice shipped in `unicode/data/16.0.0/LICENSE.txt`.
