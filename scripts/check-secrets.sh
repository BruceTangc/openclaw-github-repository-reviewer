#!/usr/bin/env bash
# check-secrets.sh — 仓库 secrets 扫描（R8 Layer1）
set -u
REPO="${1:?用法: check-secrets.sh <仓库路径>}"
cd "$REPO" || exit 1
PATTERNS='ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|Bearer [A-Za-z0-9._-]{20,}|-----BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY-----|password\s*[=:]\s*[^ ]{4,}|secret\s*[=:]\s*[^ ]{6,}|api[_-]?key\s*[=:]\s*[^ ]{8,}|token\s*[=:]\s*[^ ]{8,}'
echo "=== diff HEAD 敏感模式 ==="
git diff HEAD | grep -niE "$PATTERNS" || echo "(clean)"
echo "=== 敏感文件名 ==="
git ls-files | grep -iE '(\.env$|\.pem$|\.key$|credentials|secret)' || echo "(none)"
