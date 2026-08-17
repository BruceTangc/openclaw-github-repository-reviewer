# R5 — Architecture（架构边界）

目标：改动是否破坏架构边界（不重新设计）。

Agent OS 参考链：AGENTS.md → PROTOCOL.md → Skill → Execution

检查：
- Skill 越权承担其他 Skill 职责
- 绕过协议节点（如跳过 Permission Gate）
- 引入并行 runtime / 自造 scheduler
- 违反 OpenClaw 原生优先

判定：越界 → CHANGES_REQUIRED；权限/安全/Runtime 越界 → BLOCKED。
