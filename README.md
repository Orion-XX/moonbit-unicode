# moonbit-unicode

面向 MoonBit 的 Unicode 16.0 文本基础库，提供规范化和扩展字素簇边界。

## 当前能力

- `nfd(input)`：Unicode 16.0 canonical decomposition、规范组合类排序和算法化 Hangul 分解。
- `nfc(input)`：在 NFD 管线后执行规范组合、组合阻塞、组合排除和算法化 Hangul 组合。
- `grapheme_boundaries(input)`：按 UAX #29 返回 UTF-8 左闭右开字节范围。
- 离线生成器：从仓库内固定的 Unicode 16.0.0 数据生成确定性私有表和官方测试 fixture。

运行时复用 MoonBit core 的 `String` 标量迭代，不重复实现 UTF-8 解码，不调用 JavaScript `Intl`、ICU 或平台规范化 API。输入是 MoonBit `String`；无效 UTF-8 的行为继承 core 的字符串构造和迭代语义。本版本不提供 NFKC/NFKD、大小写折叠、排序、双向文本、区域设置、词/行分割或原始字节 API。

## 快速开始

工具链版本由 CI 固定为 MoonBit `0.1.20260819`，对应 `moonc 0.10.9+6e6c44045`。

```powershell
moon info
moon fmt
moon test
moon run examples/basic
```

作为依赖使用时，在 MoonBit 项目中添加：

```powershell
moon add Atman-Angle/moonbit-unicode
```

然后导入：

```mbt
import {
  "Atman-Angle/moonbit-unicode/src/normalization",
  "Atman-Angle/moonbit-unicode/src/grapheme",
}

let canonical = @normalization.nfc("e\\u{301}")
let decomposed = @normalization.nfd(canonical)
let clusters = @grapheme.grapheme_boundaries("👩‍👩‍👧‍👦").to_array()
```

完整可运行示例见 [`examples/basic`](examples/basic)。

## 验证

检查固定数据和 grapheme fixture：

```powershell
python tools/unicode-gen/grapheme_conformance.py --check --data unicode/data/16.0.0
moon info
moon fmt --check
moon test
moon test --target native
moon test --target wasm
moon test --target wasm-gc
moon test --target js
```

U-11 导入并执行 Unicode 16.0 `auxiliary/GraphemeBreakTest.txt` 的全部 1,093 条非注释向量。当前本地 conformance 运行报告 `Total tests: 40, passed: 40, failed: 0`，其中包含官方 normalization 和 grapheme 测试。GitHub Actions run [35491628346](https://github.com/Orion-XX/moonbit-unicode/actions/runs/35491628346) 在合并提交 `85166afb3c5553f29ee2ee80079b2d51c07f794d` 上分别通过 native、wasm、wasm-gc、js 四个 target。

## 数据来源与许可证

运行时源代码和示例采用 MIT License，见 [`LICENSE`](LICENSE)。Unicode 数据属于 Unicode, Inc.，其许可证和版权说明见 [`unicode/data/16.0.0/LICENSE.txt`](unicode/data/16.0.0/LICENSE.txt)；每个输入文件的 URL 和 SHA-256 记录在 [`manifest.json`](unicode/data/16.0.0/manifest.json)。生成文件包含 Unicode 版本、输入哈希和生成命令，不应手工编辑。

## 项目边界

本项目只承诺 Unicode 16.0.0 的 NFC、NFD 和 UAX #29 extended grapheme clusters。它不是 ICU 的替代品，也不宣称实现完整 Unicode 文本处理生态。
