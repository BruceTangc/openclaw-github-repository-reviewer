---
name: repository-reviewer
description: 独立仓库审核与 Release Gate。审核任何 Agent 对任何 Repository 产生的实际变更，在 Commit/Push 前提供独立 Release Gate（BLOCKED / CHANGES_REQUIRED / APPROVED_WITH_WARNINGS / APPROVED）。基于 OpenClaw 26.7.1 原生能力，不重复实现 Agent/Skill/Automation/Security。审核 Repository 变更时触发。
metadata:
  openclaw:
    requires:
      bins: ["gh", "git", "python3", "bash"]
---

# Repository Reviewer — 变更治理 + 独立审核 + Release Gate

> **v1.0 冻结版（2026-08-17）**。职责边界：OpenClaw 拥有 Agent/Skill/Automation/Security 运行时，
> Reviewer 只负责**审核实际变更 + 出具独立 Release Gate**。Reviewer ≠ Fixer，不自动修复、不替用户确认。

## 核心职责

审核任何 Agent 对任何 Repository 的实际变更，在 Commit/Push 前提供独立 Release Gate：

```
OpenClaw (Agents/Skills/Automation 原生)
   → Main Agent 修改 Repository
   → Working Tree
   → repository-reviewer（10 Gate 审核）
   → Release Gate（BLOCKED / CHANGES_REQUIRED / APPROVED_WITH_WARNINGS / APPROVED）
   → Commit / Push
```

## 能力边界（谁做什么）

| 能力 | OpenClaw 原生 | Reviewer |
|:--|:--:|:--:|
| Agent Runtime | ✅ | 使用（独立 Agent） |
| Sub-agent | ✅ | 使用 |
| Skill Loading / Allowlist | ✅ | 审核 |
| Automation / Heartbeat / Tasks / Task Flow / Hooks | ✅ | 审核使用是否正确 |
| Security Audit | ✅（openclaw security audit） | 调用 + 解释 |
| Git Scope / Change Completeness / 跨文件一致性 / 影响分析 / 架构 / 文档同步 / Release Gate | ❌ | ✅ |

**绝不重复造**：不做自己的 agent-runtime / skill-loader / automation-engine / security-audit。
定时触发一律用 OpenClaw 原生（Automation / Heartbeat / Hook / git pre-push），不在 Reviewer 里自造 watcher。

## 十道 Gate（R1-R10）

| # | Gate | 核心问题 |
|:--|:--|:--|
| R1 | Change Scope | 声明的改动 = 实际改动吗？（git status/diff/untracked/deleted） |
| R2 | Completeness | 有没有少改？（改 API 没同步 README/examples/tests） |
| R3 | Consistency | 代码/Skill/指令/协议/配置/文档 是否一致 |
| R4 | Impact | 改动影响面：LOW/MEDIUM/HIGH/CRITICAL |
| R5 | Architecture | 是否破坏现有架构边界（Skill 越权） |
| R6 | Documentation | 行为变了 → 受影响文档是否同步 |
| R7 | Verification | 跑项目已有测试 + openclaw doctor/security audit/skills verify |
| R8 | Security | 三层：仓库 secrets → 项目安全 → OpenClaw 安全 |
| R9 | Hygiene | logs/tmp/cache/bak/generated 是否合理（expected/ignored/tracked/unexpected） |
| R10 | Release Readiness | 这棵树能 commit / push 吗？ |

## 状态机（冻结）

```
START → DISCOVER → SNAPSHOT → CLASSIFY → REVIEW → VERIFY → DECIDE
                                                          ├── BLOCKED
                                                          ├── CHANGES_REQUIRED
                                                          ├── APPROVED_WITH_WARNINGS
                                                          └── APPROVED
```

## Snapshot 快照（一切检查的基础）

审核开始时必须先冻结快照，后续所有检查基于快照；**快照后树发生变化 = INVALIDATED，必须重新审核**：

```yaml
review_id: RVW-YYYYMMDD-XXX
repository:
  path: ...
  branch: ...
  remote: ...
git:
  head: ...
  base: ...
  tree_hash: ...
scope:
  mode: workspace
profiles:
  - openclaw-skill   # 或 agent-os / generic / software / documentation / configuration
```

## 产物

- `REVIEW-PROTOCOL.md` — 十道 Gate 的完整执行细则
- `RULES.yaml` — 严重级别、P0-P2 定义、Gate 开关
- `profiles/` — 项目类型画像（决定重点 Gate）
- `checks/` — 每道 Gate 的检查手册
- `schemas/` — review-record / finding / release-gate JSON schema
- `scripts/` — 采集脚本（collect-state/collect-diff/detect-project/verify-tree/check-secrets/check-hygiene）
- 审核结果存 `reviews/RVW-*.md`（可审计）

## 权限原则

- **只读审核**：read / exec / process / git 可用；**edit / write / apply_patch 不可用**（由 OpenClaw tools 策略强制）
- **Reviewer ≠ Fixer**：发现 P1 问题返回 `changes_required` + findings（含 required_action），**由 Main Agent 修复，Reviewer 重新审核**
- **Gate Mode（默认）**：APPROVED 后由 Main Agent commit/push；Release Authority（Reviewer 直接推送）为高级模式，运行稳定后再开放
- 即使 APPROVED，最终 push 仍由用户确认（审核负责"有没有问题"，确认负责"要不要执行"）