#!/usr/bin/env bash
# detect-project.sh — 识别仓库类型 → 输出应加载的 profiles（CLASSIFY）
set -u
REPO="${1:?用法: detect-project.sh <仓库路径>}"
cd "$REPO" || exit 1
match() { [ -n "$(find . -maxdepth 2 -name "$1" 2>/dev/null | head -1)" ]; }
if match "PROTOCOL.md" && match "AGENTS.md"; then echo "agent-os"; fi
if match "SKILL.md" && match "_meta.json"; then echo "openclaw-skill"; fi
if match "pyproject.toml" || match "package.json" || match "Cargo.toml" || match "go.mod"; then echo "software"; fi
if [ -d docs ] || match "README.md"; then echo "documentation"; fi
echo "generic"
