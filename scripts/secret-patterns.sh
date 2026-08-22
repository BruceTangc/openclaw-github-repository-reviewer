#!/usr/bin/env bash
# secret-patterns.sh — secrets 扫描机器规则源（唯一权威源，v1.0）
#
# 与 RULES.yaml 的 secret_patterns（9 条）保持同步，此为机器执行权威源。
# 与 RULES.yaml 的区别：此处已是 grep -E 直接可用的 POSIX 类写法
# （RULES.yaml 是 YAML 转义格式：\\s 需转成 [[:space:]]、引号需还原，
#  不能直接喂给 grep -E）。改动模式时必须同步修改本文件与 RULES.yaml，避免双源漂移。
#
# 用法：
#   source scripts/secret-patterns.sh
#   grep -niE "$(join_patterns)" FILE        # 或用下面的 SECRET_PATTERNS_ALL
#   grep -niE "(${SECRET_PATTERNS_ALL[*]})" FILE  # 逐条数组，可迭代
set -u

# 单条机器模式（顺序与 RULES.yaml secret_patterns 一致）
SECRET_PATTERNS_ALL=(
  'ghp_[A-Za-z0-9]{20,}'
  'sk-[A-Za-z0-9]{20,}'
  'AKIA[0-9A-Z]{16}'
  'Bearer [A-Za-z0-9._-]{20,}'
  '-----BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY-----'
  "password[[:space:]]*[=:][[:space:]]*['\"][^'\"]{4,}"
  "secret[[:space:]]*[=:][[:space:]]*['\"][^'\"]{6,}"
  "api[_-]?key[[:space:]]*[=:][[:space:]]*['\"][^'\"]{8,}"
  "token[[:space:]]*[=:][[:space:]]*['\"][^'\"]{8,}"
)

# 拼接为单个 alternation 正则（可直接喂 grep -E），如 "p1|p2|...|p9"
join_patterns() {
  local IFS='|'
  printf '%s' "${SECRET_PATTERNS_ALL[*]}"
}

# 兼容旧调用方：暴露单条 alternation（与 check-secrets.sh 旧 PATTERNS 同构）
SECRET_PATTERNS="$(join_patterns)"

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  # 直接执行模式：打印 9 条模式，自检用
  printf 'SECRET_PATTERNS: %s\n' "$SECRET_PATTERNS"
  printf 'count=%d\n' "${#SECRET_PATTERNS_ALL[@]}"
  printf 'patterns:\n'
  printf '  %s\n' "${SECRET_PATTERNS_ALL[@]}"
fi
