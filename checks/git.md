# git.md — Git 基础采集（所有 Gate 的前置，v1.1）

目标：获取仓库真实状态，作为审核事实基础。

```bash
git rev-parse --show-toplevel      # 仓库根
git branch --show-current          # 当前分支
git remote -v                      # remote
git rev-parse HEAD                 # head sha
git rev-parse origin/HEAD          # 远端主分支
git write-tree                     # index tree（仅 tracked/staged，不含 untracked）
bash scripts/fingerprint-tree.sh <repo>   # v1.1：Exact Working Tree Fingerprint（含 untracked）
```

> **v1.1 快照语义**：`git write-tree` 只反映 index/tree，**不包含 untracked**。
> 审核期间新增 untracked 文件（debug.py/.env）不会改变 write-tree → 会误判 TREE_UNCHANGED。
> 快照与 INVALIDATION 一律以 `working_tree_fingerprint` 为准（fingerprint-tree.sh：
> HEAD + index tree + staged diff(--binary) + unstaged diff(--binary) + untracked 路径与内容 整体 sha256）。

输出作为 Snapshot 的 git 段（head / index_tree / working_tree_fingerprint）。