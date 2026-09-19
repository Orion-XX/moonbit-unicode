# GitHub Project Workflow

The canonical repository is `https://github.com/Orion-XX/moonbit-unicode.git`.

Use the U-00 to U-14 task IDs as the shared language across Issues, branches,
commits, and pull requests. Keep the default branch release-ready and do task
work on a short-lived branch such as `u03-normalization-tables`.

Each commit should represent a real engineering step: a package skeleton, a
data import, an algorithm stage, a test harness, or documentation. A commit
must contain meaningful changed files and its subject should include the task
ID. Do not use empty commits, duplicate commits, or artificial splitting to
reach a commit-count requirement.

Every pull request links its Issue and reports the task scope, exact commands,
test/conformance counts, target results, and remaining risks. Unavailable
targets are reported as `unverified`, not as passes. Merge only after required
checks and review are complete.

For parallel work, give each window a separate task and branch/worktree. Do not
overwrite another window's changes or rewrite shared history. A Unicode data
version update is a dedicated maintenance task: update hashes and licenses,
regenerate outputs, rerun all official vectors, and describe behavior changes.
