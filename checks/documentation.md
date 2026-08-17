# R6 — Documentation（行为变更 → 文档同步）

不是"所有改动都要改 README"，而是"行为变了 → 受影响文档语义同步"。

```
Behavior changed?
  ├─ NO  → PASS
  └─ YES → 找受影响文档 → 对比语义
             （README/AGENTS/PROTOCOL/SKILL.md/examples/config docs）
```

判定：行为变了但文档没同步语义 → CHANGES_REQUIRED。
