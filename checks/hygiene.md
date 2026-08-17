# R9 — Hygiene（卫生）

目标：分类判断 logs/tmp/cache/bak/generated/large，不是见 .log 就 FAIL。

```bash
git ls-files | grep -iE "(\.log$|\.tmp$|\.bak|__pycache__|\.pyc$|\.DS_Store|node_modules|debug)"
git ls-files -s | awk '$4 > 1000000 {print}'   # >1MB
```

分类：expected / ignored / tracked / unexpected。
判定：unexpected → CHANGES_REQUIRED（移除 + .gitignore）。
