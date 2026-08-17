# git.md — Git 基础采集（所有 Gate 的前置）

目标：获取仓库真实状态，作为审核事实基础。

```bash
git rev-parse --show-toplevel      # 仓库根
git branch --show-current          # 当前分支
git remote -v                      # remote
git rev-parse HEAD                 # head sha
git rev-parse origin/HEAD          # 远端主分支
git write-tree                     # 工作树快照（INVALIDATION 依据）
```

输出作为 Snapshot 的 git 段。
