# R2 — Completeness（有没有少改）

目标：反向检查连带改动是否齐全。

连带矩阵：
- 改 Skill API → README/examples/tests/SKILL.md 引用
- 改 schema → 示例/校验/文档
- 改脚本 → 调用方/文档
- 改版本 → _meta.json/MANIFEST/frontmatter

判定：缺失 → CHANGES_REQUIRED + 精确 missing 文件列表。
