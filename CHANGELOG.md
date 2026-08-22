# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Fixed
- **check-secrets.sh**: 修复 staged secret 漏检（BUG-1）——`git diff HEAD` 对已 `git add` 的 staged 新文件输出为空（首次 commit 前 HEAD 亦不可用），导致 tracked 新文件中的 secret false-clean。改为同时扫描 `--cached`，堵住漏检路径。

### Consolidated
- **secret-patterns.sh**: 新增唯一机器规则源（CONS-1）。将 RULES.yaml `secret_patterns` 的 9 条模式转为 grep -E 直接可用的权威源，消除 RULES.yaml 与内嵌 PATTERNS 双源漂移的隐患。
- **check-verification.sh**: 移除 `eval "$cmd"` 命令注入面（IMP-2），改为更安全的 `bash -c` 执行方式。

## [v1.0] — 2024
### Added
- OpenClaw GitHub Repository Reviewer 首个稳定版本。
- 10 个 Gate（R1–R10）+ profile/severity 判定，输出 APPROVED / APPROVED_WITH_WARNINGS / CHANGES_REQUIRED / BLOCKED。
- scripts/ 校验脚本套件（secrets / hygiene / verification / diff / state / tree 等）。
