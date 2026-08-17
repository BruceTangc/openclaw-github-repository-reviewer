#!/usr/bin/env bash
# verify-tree.sh — 校验工作树是否与快照一致（INVALIDATION 检测）
set -u
REPO="${1:?用法: verify-tree.sh <仓库路径>}"
BASE_HASH="${2:?用法: verify-tree.sh <仓库路径> <期望tree_hash>}"
cd "$REPO" || exit 1
NOW=$(git write-tree 2>/dev/null)
if [ "$NOW" = "$BASE_HASH" ]; then
  echo "TREE_UNCHANGED"
  exit 0
else
  echo "TREE_CHANGED: $BASE_HASH -> $NOW"
  exit 1
fi
