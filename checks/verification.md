# R7 — Verification（项目验证 + OpenClaw 原生，v1.1）

目标：调用项目已有验证方式，不发明测试框架。

**验证状态机（v1.1）**：
- NOT_APPLICABLE — 工具不存在/不适用（无 pytest.ini、package.json 无 test script）→ 不阻塞
- NOT_RUN — 存在但未跑 → 记 INCOMPLETE，结合风险判断
- PASSED — 通过
- FAILED — 失败 → CHANGES_REQUIRED
- INCOMPLETE — 工具缺失/未跑完，需人工结合风险判断

**原则**：工具不存在 / 环境不满足 ≠ 测试失败。`pytest not installed` 不得直接 CHANGES_REQUIRED。

```bash
# 统一入口（v1.1）
bash scripts/check-verification.sh <repo>

# 项目已有（存在才跑；package.json 无 test script = NOT_APPLICABLE）
[ -f pytest.ini ] && pytest
[ -f package.json ] && grep -q '"test"' package.json && npm test
[ -f Cargo.toml ] && cargo test
[ -f go.mod ] && go test ./...

# OpenClaw 原生
openclaw doctor
openclaw security audit --json
openclaw skills verify        # Skill 变更必跑
```

判定：FAILED → CHANGES_REQUIRED；INCOMPLETE → 结合 R4 风险判断是否阻止；安全审计问题 → 按 R8。