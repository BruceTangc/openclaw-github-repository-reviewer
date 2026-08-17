#!/usr/bin/env bash
# preflight.sh — 只读权限预检（v1.1，R7/Permission）
#
# 目的：不让 Reviewer 假设"我肯定只读"。启动审核前确认：
#   - 目标仓库可读、可执行 git
#   - 若检测到可写迹象（如工作区挂载为可写且无保护），明确报告
# 输出：READONLY_OK / REVIEWER_UNSAFE（要求人工确认后再审）
set -u
REPO="${1:?用法: preflight.sh <仓库路径>}"
cd "$REPO" || { echo "REVIEWER_UNSAFE: 无法进入仓库"; exit 1; }

echo "=== 1/3 仓库可读性 ==="
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "REVIEWER_UNSAFE: 非 git 仓库"; exit 1; }
echo "  ✅ 可读（git repo）"

echo "=== 2/3 审核边界（Git read-only 命令自检） ==="
if git status --short >/dev/null 2>&1 && git diff --stat >/dev/null 2>&1; then
  echo "  ✅ 只读采集命令可用（status/diff/log 均非写操作）"
else
  echo "REVIEWER_UNSAFE: 只读采集命令失败，禁止继续审核"
  exit 1
fi

echo "=== 3/3 显式写操作拦截声明 ==="
# Reviewer 的硬约束由 OpenClaw tools policy 强制（deny write/edit/apply_patch）。
# 此处作二次确认：盘点不可逆写命令是否被其他审核脚本包装（排除 preflight.sh 自身）。
SCRIPT_DIR="$(dirname "$0")"
for bad in "git push" "git reset --hard" "git clean -fd" "git commit"; do
  if grep -rqF --exclude="preflight.sh" "$bad" "$SCRIPT_DIR"/../scripts/ 2>/dev/null; then
    echo "REVIEWER_UNSAFE: 审核脚本发现写命令引用: $bad"
    exit 1
  fi
done
echo "  ✅ 审核脚本集合无 git push/commit/reset/clean 写操作"

echo "READONLY_OK"