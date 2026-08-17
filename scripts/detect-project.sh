#!/usr/bin/env bash
# detect-project.sh — 识别仓库类型 → 输出应加载的 profiles（CLASSIFY）
set -u
REPO="${1:?用法: detect-project.sh <仓库路径>}"
cd "$REPO" || exit 1
match() { [ -n "$(find . -maxdepth 2 -name "$1" 2>/dev/null | head -1)" ]; }
if match "PROTOCOL.md" && match "AGENTS.md"; then echo "agent-os"; fi
if match "SKILL.md" && match "_meta.json"; then echo "openclaw-skill"; fi
if match "pyproject.toml" || match "package.json" || match "Cargo.toml" || match "go.mod" || match "setup.py"; then echo "software"; fi
if [ -d docs ] || match "README.md"; then echo "documentation"; fi
if find . -maxdepth 1 -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.toml" -o -name ".env.example" \) | grep -q . 2>/dev/null; then
  # 仅当存在非本项目核心的配置文件才标 configuration（避免 SKILL.md/RULES.yaml 误命中）
  if ! match "PROTOCOL.md"; then echo "configuration"; fi
fi
echo "generic"
