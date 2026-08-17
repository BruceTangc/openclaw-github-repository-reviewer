#!/usr/bin/env bash
# check-secrets.sh — 仓库 secrets 扫描（R8 Layer1，v1.1）
#
# v1.1：覆盖范围升级，不再只看 git diff HEAD 文本：
#   - tracked diff（staged + unstaged，--binary 含新增内容）
#   - untracked 文件全量扫描（路径 + 内容）
#   - tracked 敏感文件名（.env/.pem/.key/credentials/secret）
set -u
REPO="${1:?用法: check-secrets.sh <仓库路径>}"
cd "$REPO" || exit 1

PATTERNS='ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|Bearer [A-Za-z0-9._-]{20,}|-----BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY-----|password\s*[=:]\s*[^ ]{4,}|secret\s*[=:]\s*[^ ]{6,}|api[_-]?key\s*[=:]\s*[^ ]{8,}|token\s*[=:]\s*[^ ]{8,}'
HITS=0

hit() { echo "  ⚠️ $1"; HITS=$((HITS+1)); }

echo "=== 1/4 tracked diff（staged + unstaged, --binary） ==="
git diff HEAD --binary 2>/dev/null | grep -niE "$PATTERNS" | head -20 | while IFS= read -r l; do hit "diff(line ${l%%:*})"; done
[ "$HITS" = 0 ] && echo "  (clean)"

echo "=== 2/4 untracked 文件内容扫描 ==="
git ls-files --others --exclude-standard -z | while IFS= read -r -d '' f; do
  if [ -f "$f" ] && grep -qiE "$PATTERNS" "$f" 2>/dev/null; then
    echo "  ⚠️ untracked: $f"
    HITS=$((HITS+1))
  fi
done
[ "$HITS" = 0 ] && echo "  (clean)"

echo "=== 3/4 tracked 敏感文件名 ==="
SENS=$(git ls-files | grep -iE '(\.env$|\.pem$|\.key$|credentials|\.secret$|secrets?\.json$)' | grep -v '^scripts/check-secrets\.sh$' || true)
if [ -n "$SENS" ]; then echo "$SENS" | while IFS= read -r f; do echo "  ⚠️ 敏感文件 tracked: $f"; done; HITS=$((HITS+1)); else echo "  (none)"; fi

echo "=== 4/4 untracked 敏感文件名 ==="
UNSENS=$(git ls-files --others --exclude-standard | grep -iE '(\.env$|\.pem$|\.key$|credentials|\.secret$|secrets?\.json$)' || true)
if [ -n "$UNSENS" ]; then echo "$UNSENS" | while IFS= read -r f; do echo "  ⚠️ 敏感文件 untracked: $f"; done; HITS=$((HITS+1)); else echo "  (none)"; fi

echo "---"
if [ "$HITS" -gt 0 ]; then echo "SECRET_FOUND=$HITS"; exit 1; else echo "SECRET_FOUND=0 (clean)"; exit 0; fi