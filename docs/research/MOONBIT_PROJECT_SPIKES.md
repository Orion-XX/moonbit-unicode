# MoonBit Project Spikes

日期：2026-09-19  
模式：EXPLORE（只做最小验证，不开发完整项目）

## 1. 范围与仓库现实

当前 `D:\moonbit2` 的业务仓库实际上只有调研文档 `docs/research/MOONBIT_PROJECT_GAPS.md`，没有 MoonBit 源码、`moon.mod` 或现有业务依赖；因此 Spike 文件放在 `spikes/` 和临时目录，不修改业务代码。

工具链：

- `moon 0.1.20260819 (fc2a4ee 2026-08-19)`；`moonc -v` 为 `v0.10.9+6e6c44045 (2026-08-19)`。
- core 随工具链安装于 `C:\Users\李子睿Atman\.moon\lib\core`，版本 `0.10.9+6e6c44045`。
- Rust `rustc 1.98.0`、`cargo 1.98.0` 可用；本机没有 `wasmtime`、`wit-bindgen`、`wasm-tools` 可执行文件。

生态核查结论：`core` 已包含 `quickcheck`、UTF-8/UTF-16、Unicode scalar/Char API；不能把这些能力重新包装成“缺口”。调研文档中提到的 Extism PDK、Spin SDK、WASI Preview 1 也说明 WASM 已有早期入口。GitHub 搜索/API 不是“不存在”的证据；以下只记录实际源码、工具链和标准测试结果。

## 2. 属性测试、fuzzing、deterministic replay

### 已有实现

实际源码 `C:\Users\李子睿Atman\.moon\lib\core\quickcheck` 已提供：

- `Arbitrary` generator 与 `@quickcheck.gen/samples`；
- `@shrink.Shrink`，包含数字、字符串、数组和复合类型；
- `@quickcheck.report/check`，`count/max_size/max_shrinks/discard_ratio/seed`；
- `Falsified/Raised/GaveUp` 结构化结果、`counterexample_context`、观察统计；
- MoonBit `test` runner 集成。core 自带 `driver_test.mbt` 和 shrink 测试，证明不是只有文档声明。

### 最小实验

文件：`spikes/property-replay/property_replay.mbt`、`spikes/property-replay/property_replay_test.mbt`、`spikes/property-replay/moon.pkg`。

目标是一个极小 HTTP status-line 形状检查器（3 个 ASCII 数字），而不是用恒真函数掩盖测试框架问题。测试对同一 property 使用同一 seed `20260919` 两次，`count=100`、`max_size=12`、`max_shrinks=100`。

命令：

```powershell
moon test --target native
moon test --target native --update
```

结果：首次运行得到预期 snapshot 差异；`--update` 后再次运行通过。两次 report 的结果均为：

```text
Falsified(counterexample="", tests=1, size=0, shrinks=0, shrink_attempts=0)
```

这验证了 generator、seed replay、自动 shrink、结构化 falsification 和 test runner 接入。它没有验证 native 以外的 fuzz engine，也没有证明能自动保存 corpus 文件。

### 判断

事实：MoonBit 已有成熟的 property-testing 核心能力；从零实现 QuickCheck 不建议继续。  
推断：仍有一个较小的工程缺口，即把 `report` 接到持久化失败样例、CI artifact、外部 libFuzzer/AFL corpus 和 parser-specific generator。  
未知：当前是否存在活跃、统一的第三方 fuzz bridge，不能仅由 GitHub 搜索否定。

建议：**有价值但需要缩小范围**。项目边界应是 `property + shrink + replay + CI/fuzz bridge`，而非再次实现 generator/shrinker。估算 3--6 人周；风险是 runner 输出格式稳定性、跨 target 随机性、异步/状态模型和 corpus 兼容。

参考：[MoonBit core quickcheck README](https://github.com/moonbitlang/core/tree/main/quickcheck)、[QuickCheck](https://hackage.haskell.org/package/QuickCheck)、[Hypothesis](https://hypothesis.readthedocs.io/)。

## 3. Unicode NFC/NFD 与 grapheme segmentation

### 已有实现与最小实验

core 已覆盖 `moonbitlang/core/encoding/utf8` 的严格 `decode`、`decode_lossy`，以及 `String::iter/to_array` 的 Unicode scalar 迭代；其测试引用 Unicode 16.0 Chapter 3 Table 3-8--3-11 的非法 UTF-8 向量。通过 `rg` 检索 `core` 未发现 NFC/NFD/NFKC/NFKD 或 grapheme segmentation API。

临时模块：`D:\moonbit2\.unicode-spike-20260919`。关键文件为 `unicode_spike_test.mbt`、`moon.pkg`。

命令及结果：

```powershell
moon -C D:\moonbit2\.unicode-spike-20260919 test --target native
# Total tests: 2, passed: 2, failed: 0.
```

真实向量：

- `e\u{301}` 按 scalar 迭代得到 2 个字符；规范化 NFC 应是 1 个预组合作为对照；
- `👩‍👩‍👧‍👦` 按 scalar 迭代得到 7 个字符；UAX #29 extended grapheme cluster 应是 1 个；
- 严格 UTF-8 对 `C0 AF` 拒绝，lossy 模式得到两个 U+FFFD；合法中文通过；
- 默认模板的 `moon test --target all` 能列出 wasm/wasm-gc/js/native，但无测试 entry；当前 Spike 只实际跑了 native，不能声称多 target 已通过。

### 判断

事实：UTF-8 和 scalar 层已有实现；NFC/NFD 与 grapheme 是真实缺口。  
推断：最合理的独立库是“版本化 Unicode 数据生成器 + NFC/NFD + UAX #29 grapheme”，而不是重复 UTF-8。  
未知：完整数据表在 JS/WASM/native 上的体积和速度，必须在生成器完成后测量。

标准与测试套件：

- [UAX #15 Unicode Normalization](https://www.unicode.org/reports/tr15/)
- [UAX #29 Text Segmentation](https://www.unicode.org/reports/tr29/)
- [Unicode 16.0 NormalizationTest.txt](https://www.unicode.org/Public/16.0.0/ucd/NormalizationTest.txt)
- [Unicode 16.0 GraphemeBreakTest.txt](https://www.unicode.org/Public/16.0.0/ucd/auxiliary/GraphemeBreakTest.txt)

建议：**值得继续**，但先限定 NFC/NFD 和 extended grapheme cluster。Spike 到可发布库约 6--10 人周；完整 NFKC、case folding、word/line break 和安全 profile 约 3--6 人月。主要风险是 Unicode 版本升级、组合类/Hangul 边界、表压缩、内存和跨 target 一致性。

## 4. WASI Component Model / WIT

### 最小解析与映射实验

文件：`spikes/wit-component/fixture.wit`、`spikes/wit-component/src/main.rs`、`spikes/wit-component/generated_types.mbt`、`spikes/wit-component/Cargo.toml`。

fixture 包含 `record item`、`variant lookup-error`、`list<item>`、`result<item, lookup-error>` 和 `resource session`，并有 get/list/open/close 函数。使用官方 `wit-parser 0.259.0`：

```powershell
cargo run --quiet -- fixture.wit
```

输出：

```text
parsed package=Id { idx: 0 } interfaces=1 worlds=0
mapping: record -> struct; variant -> enum; list<T> -> Array[T]; result<T,E> -> Result[T,E]; resource -> opaque handle
```

这证明 WIT 语法和关键类型可被当前 parser 解析，也给出了 MoonBit 类型映射的最小候选。首次故意使用字段名 `list` 时 parser 报 `expected type, resource or func, found keyword list`；改为 `list-items` 后通过，记录了 WIT 关键字约束。

### 互操作边界

事实：本机没有 Wasmtime、wit-bindgen 或 wasm-tools；当前 MoonBit 仓库也没有现成 Component Model guest binding 生成器。  
因此本 Spike **没有**伪称完成 guest WASM、Rust host、错误传播或 resource drop 互调；这些验收项是失败/未完成证据，而不是通过。

需要补做的真实验证：WIT -> MoonBit 生成代码、canonical ABI、`result` 错误传播、resource drop/借用生命周期、Rust/Wasmtime host、WASM/native 目标限制，以及 Preview 2/Component Model 版本矩阵。

判断：**值得继续，但当前不适合直接承诺完整开源项目**。已有 PDK/Spin/WASI Preview 1 入口，方向不是空白；真正增量是可维护的 WIT binding generator + 版本锁定的 component conformance。估算 10--16 人周；风险最高的是工具链版本漂移、canonical ABI、resource 语义和多 target 限制。建议先安装固定版本 Wasmtime/wasm-tools 后再做第二阶段 Spike。

参考：[WIT format](https://component-model.bytecodealliance.org/design/wit.html)、[WASI](https://wasi.dev/)、[wit-parser](https://crates.io/crates/wit-parser)、[WebAssembly Component Model](https://component-model.bytecodealliance.org/)。

## 5. 推荐顺序与淘汰项

不强行指定唯一第一名。基于当前证据，建议并行优先级为：

1. Unicode：缺口最明确，标准测试套件清晰，范围可收敛；
2. Property/fuzz bridge：底层 QuickCheck 已成熟，适合做小而有复用价值的工程增量；
3. WIT binding：技术价值高，但先补齐固定 Wasmtime/wasm-tools 环境和 guest/host 互操作证据。

“从零实现 QuickCheck”、重复 core UTF-8/scalar API、或只写一个 WIT 文本 parser，应淘汰。完整 Unicode ICU、完整 Component Model runtime、或全套 fuzz engine 都超出本 Spike 证明的可交付范围。

## 6. 证据状态矩阵

| 方向 | 现有实现 | Spike | 规范/互操作 | 建议 | 核心未验证项 |
|---|---|---|---|---|---|
| 属性测试 | core quickcheck 已有 | native 通过，seed/shrink/replay 通过 | 真实 parser 形状目标；无外部 fuzz engine | 有价值但缩小 | corpus 持久化、fuzz bridge、跨 target |
| Unicode | UTF-8/scalar 已有，无 normalization/grapheme | native 2/2 | UAX #15/#29 向量已选定，尚未导入全量 | 值得继续 | 表生成、全量向量、多 target/性能 |
| WIT/Component | PDK/Preview 1 线索，无 binding 证据 | wit-parser 解析通过 | 无 Wasmtime/guest-host 运行 | 有价值但先补环境 | ABI、错误、resource、WASM 互操作 |

本报告没有宣称任何方向已经是完整开源项目；它只把当前真实能力、最小可运行证据、失败边界和下一阶段工作量分开记录。
