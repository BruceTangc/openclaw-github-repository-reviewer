# R7 — Verification（项目验证 + OpenClaw 原生）

目标：调用项目已有验证方式，不发明测试框架。

```bash
# 项目已有
[ -f pytest.ini ] && pytest
[ -f package.json ] && npm test
[ -f Cargo.toml ] && cargo test
[ -f go.mod ] && go test ./...

# OpenClaw 原生
openclaw doctor
openclaw security audit --json
openclaw skills verify        # Skill 变更必跑
```

判定：验证失败 → CHANGES_REQUIRED。
