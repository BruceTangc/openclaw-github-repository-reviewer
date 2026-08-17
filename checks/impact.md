# R4 — Impact（影响面分级）

目标：沿依赖关系追踪影响面 → LOW/MEDIUM/HIGH/CRITICAL。

追踪链：
```
Changed File
 → imports/references/callers（grep 引用）
 → 依赖的 skills/docs/tests/config
 → automation/hooks 是否引用
 → 是否触及协议/权限/安全边界
```

输出：每个变更文件的 Impact 分级 + 依据。
HIGH/CRITICAL 必须给出影响分析段落；无法确认 → finding。
