# R3 — Consistency（跨文件语义一致）

目标：代码/Skill/指令/协议/配置/文档/示例/测试之间一致。

重点：
- 术语统一（禁止平行词：如 learning ledger 与 evidence 混用）
- 版本号一致（frontmatter/_meta.json/MANIFEST）
- 阈值一致（代码默认值 = 文档规则）
- 配置真实生效（不是死配置）

```bash
grep -rn "旧术语" . --include="*.md" --include="*.py"
```

判定：不一致 → CHANGES_REQUIRED。
