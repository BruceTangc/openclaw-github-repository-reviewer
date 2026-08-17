# R1 — Change Scope（声明的 vs 实际的）

目标：验证主 Agent 声明的改动范围与实际改动一致。

```bash
git status --short
git diff --stat
git diff --cached --stat
git diff HEAD --name-status        # A/M/D/R
git ls-files --others --exclude-standard   # untracked
```

判定：
- 实际改动 ⊄ 声明范围 → CHANGES_REQUIRED，列出多余文件
- untracked 中出现敏感/临时文件 → finding
