---
name: pr-definition-of-done
description: Use when preparing a pull request for review or before pushing. Checklist of commit conventions, Rego policy tests at 100% coverage, BATS tests, code quality checks, and CI check requirements.
---

# PR Definition of Done

## Overview

Every PR must pass CI checks, follow commit conventions, include tests with 100% coverage for policies, and avoid unnecessary whitespace changes.

## When to Use

- Before pushing a PR for review
- When CI checks fail unexpectedly
- When reviewing someone else's PR

## Pre-Push Checklist

### Commits
- [ ] Conventional format: `type(JIRA-ID): description` (e.g., `feat(STONEINTG-1641): add AI skills`)
- [ ] Types: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`
- [ ] **Description starts lowercase** (gitlint custom rule UC1 — this is strict)
- [ ] Title < 72 chars, body lines < 72 chars
- [ ] Signed off (DCO): `git commit -s`
- [ ] AI-assisted work: add `Assisted-by: <tool-name>` trailer

### Testing
- [ ] New/modified Rego policies: add/update unit tests in `unittests/test_{scanner}/`
- [ ] New/modified bash functions: add/update BATS tests in `unittests_bash/`
- [ ] **OPA policy coverage at 100%** — CI enforces this strictly
- [ ] `opa test policies unittests unittests/test_data -c` passes
- [ ] `bats unittests_bash` passes

### Code Quality
- [ ] `shellcheck -s bash test/utils.sh` passes (excludes conftest.sh, selftest.sh)
- [ ] `hadolint Dockerfile` passes (with standard ignores: DL3003,DL3013,DL3041,DL4006)
- [ ] No whitespace or newline changes in unrelated code
- [ ] No whitespace or tabs on empty lines
- [ ] Files must end with exactly one newline character (no extra trailing newlines)
- [ ] No removal of unrelated code

### Security
- [ ] Never commit secrets, keys, or credentials

## What CI Checks

| Check | Workflow | What fails it |
|-------|----------|---------------|
| OPA unit tests | `pr-checks.yaml` / `opa_policies_unittest` | Any test failure or coverage < 100% |
| BATS tests | `pr-checks.yaml` / `bash_unittests` | Any BATS test failure |
| Shellcheck | `pr-checks.yaml` / `shellcheck` | Violations in `test/` (excludes conftest.sh, selftest.sh) |
| Hadolint | `pr-checks.yaml` / `Dockerfile-linter` | Dockerfile lint violations |
| YAML lint | `pr-checks.yaml` / `YAML-Linter` | yamllint violations |
| Gitlint | `pr-checks.yaml` / `gitlint` | Non-conventional format, title > 72 chars, uppercase after colon |
| Tekton build | `.tekton/` | Image build failure, security scans |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Commit description starts uppercase | Must start lowercase — gitlint custom rule UC1 enforces |
| OPA coverage drops below 100% | Add tests for every new policy rule line |
| Added whitespace to unrelated lines | Review diff carefully, revert formatting-only changes |
| Forgot to add test data fixture | New policies need test data in `unittests/test_data/` |
| `shellcheck` passes locally but fails in CI | Run with `-s bash` flag: `shellcheck -s bash test/utils.sh` |
