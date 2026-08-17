# OpenClaw GitHub Repository Reviewer

> 独立 的 GitHub 仓库审核与 Release Gate Agent —— 基于 OpenClaw 26.7.1 原生能力，
> 专门负责 **变更治理 + 独立审核 + Release Gate**，不重复实现 Agent/Skill/Automation/Security。

> **定位说明**：GitHub 是主要托管场景，Reviewer 本身以 **Git Repository** 为审核边界
> （同样适用于 OpenClaw skill / Agent OS / software / documentation / configuration 等项目）。

审核任何 Agent 对任何 Repository 产生的实际变更，在 Commit / Push 前提供独立的 Release Gate：

```
OpenClaw (Agents/Skills/Automation 原生)
   → Agent 修改 Repository
   → Working Tree
   → repository-reviewer（10 Gate 审核）
   → Release Gate（BLOCKED / CHANGES_REQUIRED / APPROVED_WITH_WARNINGS / APPROVED）
   → Commit / Push
```

## 能力边界（不重复造 OpenClaw）

| 能力 | OpenClaw 原生 | Reviewer |
|:--|:--:|:--:|
| Agent Runtime / Sub-agent / Skill Loader / Skill Allowlist | ✅ | 使用/审核，不实现 |
| Automation / Heartbeat / Tasks / Task Flow / Hooks / Standing Orders | ✅ | 审核使用是否正确，不实现 |
| Security Audit / Skills Verify / Doctor | ✅（openclaw security audit） | 调用 + 解释 |
| Git 变更识别 / 完整性 / 跨文件一致性 / 影响分析 / 架构 / 文档同步 / 回归评估 / Release Gate / 审核失效 / 审核记录 | ❌ | ✅ 独有职责 |

## 十道 Gate（R1-R10）

| # | Gate | 核心问题 |
|:--|:--|:--|
| R1 | Change Scope | 声明的改动 = 实际改动？ |
| R2 | Completeness | 有没有少改？ |
| R3 | Consistency | 代码/Skill/指令/协议/配置/文档 是否一致 |
| R4 | Impact | 影响面 LOW/MEDIUM/HIGH/CRITICAL |
| R5 | Architecture | 是否破坏架构边界 |
| R6 | Documentation | 行为变了 → 受影响文档同步？ |
| R7 | Verification | 项目已有测试 + openclaw doctor/security/skills check |
| R8 | Security | 三层：仓库 secrets → 项目安全 → OpenClaw 安全 |
| R9 | Hygiene | logs/tmp/cache/bak/generated 合理？ |
| R10 | Release Readiness | 这棵树能 commit / push 吗？ |

## 状态机（冻结）

```
START → DISCOVER → SNAPSHOT → CLASSIFY → REVIEW → VERIFY → DECIDE
                                                          ├── BLOCKED
                                                          ├── CHANGES_REQUIRED
                                                          ├── APPROVED_WITH_WARNINGS
                                                          └── APPROVED
```

- **Snapshot 快照**：审核开始先冻结 `review_id + tree_hash`；快照后树变化 = **INVALIDATED，必须重审**。
- **Reviewer ≠ Fixer**：只出 findings（含 required_action），修复由 Main Agent 完成，修完重审。
- **Gate Mode 默认**：APPROVED 后由 Main Agent commit/push，最终 push 仍需用户明确确认。

## 目录结构

```
├── AGENTS.md                # 核心职责 + 铁律（只读/快照/Gate Mode）
├── SKILL.md                 # Skill 入口
├── REVIEW-PROTOCOL.md       # 十道 Gate 细则 + 状态机 + Invalidation
├── RULES.yaml               # 严重级别 P0/P1/P2 + Gate 开关 + 原生验证命令
├── profiles/                # generic/software/documentation/configuration/openclaw-skill/agent-os
├── checks/                  # R1-R10 每道 Gate 速查卡
├── schemas/                 # review-record / finding / release-gate JSON Schema
└── scripts/                 # preflight / fingerprint-tree / collect-state / collect-diff / detect-project / verify-tree / check-secrets / check-verification / check-hygiene / collect-remote
```

## 安装使用

1. 将本仓库作为 Agent workspace（或复制核心资产到你的 Agent workspace）。
2. 配置 Agent 只读权限：`deny=[write, edit, apply_patch]`。
3. 在 Main Agent 的 AGENTS.md 中加入 Release Gate 硬规则：
   > Commit/Push 前必经 repository-reviewer 10 Gate 审核；BLOCKED / CHANGES_REQUIRED 禁止推送；
   > 审核基于 Snapshot，树变化 = INVALIDATED 必须重审；APPROVED 仍需用户确认。

## 审核记录

每次审核产出 `reviews/RVW-YYYYMMDD-XXX.md`（Snapshot + findings + 结论），
findings 结构：`id / severity(P0-P2) / gate(R1-R10) / file / required_action`。

## License

MIT