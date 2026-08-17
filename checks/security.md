# R8 — Security（三层安全）

Layer 1 仓库 secrets（无条件）：
```bash
git diff HEAD | grep -niE "(ghp_|sk-|AKIA|Bearer |BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY|password\s*[=:]|secret\s*[=:]|api[_-]?key\s*[=:]|token\s*[=:])"
# .env/*.pem/*.key/credentials* 是否入库
```

Layer 2 项目安全：危险权限/不安全命令/依赖跳变/可疑脚本。

Layer 3 OpenClaw 安全（配置/skill/插件变更时）：
```bash
openclaw security audit --json
openclaw security audit --deep --json
```

判定：L1/L2 命中 → BLOCKED；L3 高危项 → BLOCKED。
