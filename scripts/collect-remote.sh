#!/usr/bin/env bash
# collect-remote.sh — GitHub Remote State Check（v1.1，gh 实际使用）
#
# 目的：让 gh 在审核链中真实发挥作用——远程状态不一致也是 Release Gate 的输入。
# 输出：branch / remote / ahead / behind / PR open / 是否可推送
set -u
REPO="${1:?用法: collect-remote.sh <仓库路径>}"
cd "$REPO" || exit 1

echo "=== GitHub Remote State（gh） ==="
BRANCH=$(git branch --show-current 2>/dev/null || echo unknown)
echo "branch=$BRANCH"

REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "(no remote)")
echo "remote=$REMOTE_URL"
if [ "$REMOTE_URL" = "(no remote)" ] || ! command -v gh >/dev/null 2>&1; then
  echo "gh=SKIPPED (无 remote 或 gh 未安装 — 远程状态无法确认，本地审核仍可继续)"
  exit 0
fi

echo "ahead/behind: $(git rev-list --left-right --count origin/HEAD...HEAD 2>/dev/null || echo unknown)"

# 远端仓库识别（支持 git@github.com:owner/repo 与 https://github.com/owner/repo）
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's#^.*github.com[:/]##; s#\.git$##' 2>/dev/null)
if [ -n "$OWNER_REPO" ] && gh repo view "$OWNER_REPO" >/dev/null 2>&1; then
  PR_OPEN=$(gh pr list --repo "$OWNER_REPO" --head "$BRANCH" --state open --json number --jq 'length' 2>/dev/null || echo "?")
  echo "pr_open=$PR_OPEN"
  PROTECTED=$(gh api "repos/$OWNER_REPO/branches/$BRANCH/protection" --jq '.required_status_checks != null or .enforce_admins != null' 2>/dev/null || echo "false")
  echo "branch_protected=$PROTECTED"
else
  echo "gh=UNAVAILABLE (远程仓库不可查询 — 不阻塞本地审核，但远程状态未知)"
fi