# R8 — Security（三层安全，v1.0）

Layer 1 仓库 secrets（无条件执行，统一入口）：
```bash
bash scripts/check-secrets.sh <repo>
# 覆盖范围（v1.0）：
#   - tracked diff（staged + unstaged，--binary 含新增内容）
#   - untracked 文件内容扫描（-z 安全处理空格文件名）
#   - tracked 敏感文件名（.env/.pem/.key/credentials/secret）
#   - untracked 敏感文件名
# 判定：SECRET_FOUND > 0 → BLOCKED
```

Layer 2 项目安全：危险权限声明/不安全命令（rm -rf、curl | bash、eval）/依赖跳变/可疑脚本。

Layer 3 OpenClaw 安全（配置/skill/插件变更时）：
```bash
openclaw security audit --json
openclaw security audit --deep --json
```

判定：L1/L2 命中 → BLOCKED；L3 高危项 → BLOCKED。