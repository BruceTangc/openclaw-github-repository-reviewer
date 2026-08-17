#!/usr/bin/env bash
# collect-state.sh — 采集仓库基础状态（DISCOVER/SNAPSHOT 前置）
set -u
REPO="${1:?用法: collect-state.sh <仓库路径>}"
cd "$REPO" || exit 1
echo "repo=$(pwd)"
echo "branch=$(git branch --show-current 2>/dev/null)"
echo "head=$(git rev-parse HEAD 2>/dev/null)"
echo "tree_hash=$(git write-tree 2>/dev/null)"
echo "remote=$(git remote get-url origin 2>/dev/null)"
echo "--- status ---"
git status --short
echo "--- upstream ---"
git rev-parse origin/HEAD 2>/dev/null || echo "(no upstream)"
