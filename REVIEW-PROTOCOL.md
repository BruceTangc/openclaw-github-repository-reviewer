# Review Protocol — repository-reviewer 十道 Gate 执行细则

> **v1.0 冻结版（2026-08-17）**。本协议定义每次审核必须执行的完整链路。
> 架构冻结：后续只在 profiles/、checks/、scripts/ 增加能力，不改变核心执行链。

## 0. 核心状态机（冻结）

```
START → DISCOVER → SNAPSHOT → CLASSIFY → REVIEW → VERIFY → DECIDE
                                                          ├── BLOCKED
                                                          ├── CHANGES_REQUIRED
                                                          ├── APPROVED_WITH_WARNINGS
                                                          └── APPROVED
```

### DECIDE 四种结论语义

| 结论 | 含义 | 动作 |
|:--|:--|:--|
| BLOCKED | 存在 P0 安全问题/破坏性变更 | 禁止 commit/push；列 findings；Main Agent 修复后重审 |
| CHANGES_REQUIRED | 存在 P1 问题或 Declared ≠ Actual Scope | 禁止 commit/push；列 findings + required_action；修复后重审 |
| APPROVED_WITH_WARNINGS | 仅 P2 级建议 | 可 commit/push；findings 记录为建议项 |
| APPROVED | 所有 Gate 通过 | 可 commit/push（仍需用户最终确认） |

## 1. Snapshot（先冻结，再审核）

审核开始时**必须**生成快照。快照后工作树发生变化 → **INVALIDATED，必须重新审核**。

```yaml
review_id: RVW-YYYYMMDD-XXX
repository:
  path: /abs/path
  branch: main
  remote: origin
git:
  head: <sha>
  base: <origin/main sha>
  tree_hash: <git write-tree 的输出>
scope:
  mode: workspace        # workspace | staged | commit-range
  declared: "<主 Agent 声称的改动范围>"
profiles: [openclaw-skill, agent-os]   # 由 CLASSIFY 决定
```

> `git write-tree` 是冻结工作树当前状态的可靠手段；任何后续检查发现
> `git write-tree` 输出与快照不一致 → 立即 INVALIDATED。

## 2. 十道 Gate

### R1 — Change Scope（声明的 vs 实际的）

**目标**：解决"我只改了 X，实际改了 Y"的声明漂移。

```bash
git status --short
git diff --stat
git diff --cached --stat
git diff HEAD --name-status    # A/M/D/R 完整清单
git ls-files --others --exclude-standard   # untracked
```

**判定**：
- Declared Scope ≠ Actual Scope → **CHANGES_REQUIRED**（列出多余/缺失文件）
- 存在意外 untracked（如 debug.log、config.yaml 私改）→ finding

### R2 — Completeness（有没有少改？）

**目标**：反向检查——改了一个点，连带该改的地方改了没。

典型连带关系：
- 改 Skill API → README / examples / tests / SKILL.md 引用同步？
- 改 schema → 示例、校验、文档同步？
- 改脚本 → 调用它的文档/其他脚本同步？
- 改版本 → `_meta.json` / MANIFEST / frontmatter 全部一致？

**判定**：检测到连带缺失 → **CHANGES_REQUIRED**（每条给出精确 missing 文件）。

### R3 — Consistency（跨文件语义一致）

**目标**：代码 / Skill / Agent 指令 / 协议 / 配置 / Docs / Examples / Tests 的一致性。

重点检查：
- 同一概念在不同文件命名/术语一致（如 Evidence / Candidate 不混用平行词）
- SKILL.md frontmatter(version) vs `_meta.json` vs MANIFEST
- 阈值/规则在代码与文档一致（如 min_recurrence）
- 配置项实际被代码读取（不是死配置）

```bash
grep -rn "learning ledger\|经验事件" . --include="*.md" --include="*.py"   # 平行术语残留
```

**判定**：不一致 → **CHANGES_REQUIRED**。

### R4 — Impact（影响面分级）

**目标**：沿依赖关系追踪影响面，输出 LOW / MEDIUM / HIGH / CRITICAL。

追踪链：
```
Changed File
 → imports / references / callers（grep 引用）
 → 依赖它的 skills / docs / tests / config
 → automation / hooks 是否引用
 → 是否影响协议/权限/安全边界
```

**判定**：HIGH/CRITICAL → 必须给出影响分析段落；无法确认影响面 → 列为 finding 要求补充分析。

### R5 — Architecture（架构边界）

**目标**：改动是否破坏既有架构边界——不重新设计，只查越界。

Agent OS 参考链：`AGENTS.md → PROTOCOL.md → Skill → Execution`
检查点：
- Skill 是否开始承担另一个 Skill 的职责（如 memory 写了知识声明）
- 是否绕过既有协议节点（如跳过 Permission Gate）
- 是否引入并行 runtime / 自造 scheduler（违反 Design rule）
- 是否违反"OpenClaw 原生优先"

**判定**：越界 → **CHANGES_REQUIRED**；重大越界（权限/安全/Runtime）→ **BLOCKED**。

### R6 — Documentation（行为变更 → 文档同步）

**目标**：不是"所有改动都要改 README"，而是"行为变了 → 受影响文档语义同步"。

```
Behavior changed?
  ├─ NO  → 通过
  └─ YES → Find affected docs → Compare semantics
             （README / AGENTS.md / PROTOCOL.md / SKILL.md / examples / config docs）
```

**判定**：行为变了但受影响文档未同步语义 → **CHANGES_REQUIRED**。

### R7 — Verification（项目验证 + OpenClaw 原生验证）

**目标**：调用项目已有验证方式 + OpenClaw 原生验证，不发明测试框架。

项目已有测试：
```bash
[ -f pytest.ini ] && pytest
[ -f package.json ] && npm test        # 或 pnpm test
[ -f Cargo.toml ] && cargo test
[ -f go.mod ] && go test ./...
```
OpenClaw 原生验证（适用时）：
```bash
openclaw doctor
openclaw security audit --json
openclaw skills verify        # 审核 Skill 变更时必跑
```

**判定**：验证失败 → **CHANGES_REQUIRED**；安全审计发现问题 → 按 R8 处理。

### R8 — Security（三层安全）

**Layer 1 — Repository secrets**（无条件执行）：
```bash
git diff HEAD | grep -niE "(ghp_|sk-|AKIA|Bearer |BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY|password\s*[=:]|secret\s*[=:]|api[_-]?key\s*[=:]|token\s*[=:])"
# + 检查 .env / *.pem / *.key / credentials* 是否入库
```

**Layer 2 — Project security**：
- 危险权限声明（系统级写、网络暴露）
- 不安全命令（rm -rf、curl | bash、eval）
- 依赖变更（package.json / requirements.txt 大版本跳变）
- 可疑脚本（混淆、base64 payload）

**Layer 3 — OpenClaw security**（变更涉及 OpenClaw 配置/skill/插件时）：
```bash
openclaw security audit --json          # 必跑
openclaw security audit --deep --json   # 配置变更或暴露网络面时
```

**判定**：L1 命中 → **BLOCKED**；L2 命中 → **BLOCKED**（危险）或 **CHANGES_REQUIRED**（需解释）；L3 审计高危项 → **BLOCKED**。

### R9 — Hygiene（卫生）

**目标**：logs/tmp/cache/debug/bak/generated/large files 的分类判断，不是见 .log 就 FAIL。

```bash
git ls-files | grep -iE "(\.log$|\.tmp$|\.bak|__pycache__|\.pyc$|\.DS_Store|node_modules|debug)" 
git ls-files -s | awk '$1 ~ /^-/ && $4 > 1000000 {print}'   # >1MB 大文件
```

分类判断：`expected`（仓库惯例保留）/ `ignored`（.gitignore 已排除）/ `tracked`（意外入库）/ `unexpected`（违规）。

**判定**：unexpected 入库 → **CHANGES_REQUIRED**（要求移除 + 加 .gitignore）。

### R10 — Release Readiness（最终裁决）

回答两个问题：
1. **Can this exact tree be committed?** —— R1-R9 全部通过？
2. **Can this exact tree be pushed?** —— 用户/Protocol 授权到位？force push 授权？目标分支保护？

**判定**：输出最终状态机结论（DECIDE）。

## 3. Review Record（可审计产出）

审核完成后写入 `reviews/RVW-YYYYMMDD-XXX.md`：

```yaml
review_id: RVW-20260817-001
result: APPROVED | APPROVED_WITH_WARNINGS | CHANGES_REQUIRED | BLOCKED
snapshot: { ... }          # 冻结时的完整快照
findings:                  # 每条符合 schemas/finding.json
  - id: RVW-001
    severity: P1 | P2
    gate: R3
    file: README.md
    message: "..."
    required_action: "..."
gates:                     # R1-R10 逐项结果
  R1: PASS | FAIL | WARN
  ...
verified_at: <time>
```

## 4. Invalidation（快照失效）

```
APPROVED → 工作树发生变化（git write-tree 变） → INVALIDATED → 必须重新审核
```

- 不做"应该只是小修改"的假设。
- INVALIDATED 时丢弃原 APPROVED 结论并告知用户，重新走完整状态机。

## 5. Reviewer 权限边界

- 只读：read / exec(read-only) / process / git 查看
- 禁止：edit / write / apply_patch（由 OpenClaw tools 策略强制）
- Reviewer ≠ Fixer：findings 给 Main Agent 修；修完重审
- 最终 commit/push 由 Main Agent（Gate Mode）执行，且仍需用户确认