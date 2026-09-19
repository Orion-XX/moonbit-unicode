# Unicode Library Development Pack

This directory is the implementation contract for an AI coding workflow. Read
`../../AGENTS.md` first; it contains repository-wide rules that every task
inherits. These documents define the intended first release, not capabilities
already implemented in this repository.

## Reading Order

1. `00_PROJECT_BRIEF.md` defines the product boundary and release definition.
2. `01_ARCHITECTURE.md` defines packages, ownership, data flow, and APIs.
3. `02_DATA_PIPELINE.md` defines pinned Unicode inputs and deterministic code
   generation.
4. `03_API_AND_TEST_CONTRACT.md` defines observable behavior and test oracles.
5. `04_TASK_BREAKDOWN.md` contains independently assignable task cards.
6. `05_CONFORMANCE_AND_BENCHMARKS.md` defines the release evidence.

## Agent Handoff Template

Use this prompt with one task card at a time:

```text
Implement task <ID> from docs/development/04_TASK_BREAKDOWN.md.
Read AGENTS.md and every dependency named by the task before editing.
Do not implement adjacent tasks. Run the task's required commands.
Report changed files, generated-data provenance, test commands and results,
conformance counts, unverified targets, and unresolved risks.
```

Do not assign a task whose prerequisites are incomplete. The only approved
parallel tracks after U-00 are normalization (U-01--U-08) and grapheme
generation/implementation (U-09--U-11); both still depend on the common data
pipeline contract.

## Short Dispatch Prompt

Use this compact prompt when assigning one task to an AI coding window:

```text
完成 `docs/development/04_TASK_BREAKDOWN.md` 中的 `<TASK_ID>`。
先阅读 `AGENTS.md` 和该任务的前置依赖，确认前置任务确实完成。
严格按任务卡实现，不提前做其他任务，不覆盖其他窗口的改动。
运行任务卡要求的验证命令，并在完成后报告修改文件、实际命令及结果、
验收情况、未验证内容和剩余风险。
在独立分支上工作，提交一个或多个有实际内容的清晰 commit；commit
信息包含 `<TASK_ID>`。不要使用空提交、重复提交或仅为增加数量的拆分。
完成后说明分支名、commit SHA 和是否已准备好提交 PR。
```

提交应反映真实工作阶段，例如项目骨架、数据管线、算法实现、测试和
文档，而不是把同一改动机械拆成多次。申报所需的有效 commit 数量应由
持续开发自然产生；不能用空提交或重复提交补足。
