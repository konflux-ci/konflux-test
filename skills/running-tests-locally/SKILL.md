---
name: running-tests-locally
description: Use when running OPA policy unit tests, BATS bash tests, shellcheck, hadolint, or conftest integration tests locally. Covers test commands, coverage requirements, test data, and prerequisites.
---

# Running Tests Locally

## Overview

Tests are split into OPA Rego unit tests (policies/), BATS bash tests (utils.sh), conftest integration tests (policy/data integration), and linters (shellcheck, hadolint, yamllint).

## When to Use

- Running tests before pushing
- Debugging test failures
- Checking code coverage
- Understanding test infrastructure

## Quick Reference

| Command | What it does |
|---------|-------------|
| `opa test policies unittests unittests/test_data -c` | OPA policy unit tests with coverage |
| `bats unittests_bash` | All BATS bash unit tests |
| `shellcheck -s bash test/utils.sh` | Lint bash functions |
| `hadolint Dockerfile` | Lint Dockerfile (ignore DL3003,DL3013,DL3041,DL4006) |
| `yamllint .` | Lint all YAML files |

## OPA Policy Tests

**Prerequisites:** install `opa` binary (v0.56.0 used in CI)

**Command:** `opa test policies unittests unittests/test_data -c`

**Coverage requirement:** **100%** — every line of policy code must be covered by at least one test. CI enforces this with jq assertion: `coverage >= 100.00`.

**Coverage reporting:**
```bash
opa test --coverage --format json policies unittests unittests/test_data \
  | opa eval --data hack/simplecov.rego data.simplecov.from_opa > coverage.json
```

This generates codecov-compatible JSON for CI upload.

## BATS Bash Tests

**Prerequisites:** bats v1.8.2, jq, cosign

**Run all tests:**
```bash
bats unittests_bash
```

**Run single test file:**
```bash
bats unittests_bash/test_utils.bats
```

**Run tests matching pattern:**
```bash
bats unittests_bash/test_utils.bats -f "test name pattern"
```

Tests source `test/utils.sh` directly and mock external tools (skopeo, opm, cosign).

## Conftest Integration Tests

**File:** `test/conftest.sh` (BATS format, separate from unit tests)

**Setup:**
```bash
export POLICY_PATH=policies
```

**Run:**
```bash
bats test/conftest.sh
```

Tests the actual conftest CLI invocation against real policies, not just Rego logic. Uses three namespaces:
- `--namespace required_checks` — blocking policies
- `--namespace optional_checks` — advisory policies
- `--namespace fbc_checks` — FBC-specific policies

## Image Smoke Test

**File:** `test/selftest.sh`

Validates the built Docker image has:
- Required binaries: yq, skopeo, snyk, ec, cosign, clamscan
- conftest CLI working with all three namespaces
- parse_test_output bash function correct
- Clair/scanning API integration functional

Run inside the container after building the image (automated in integration test pipeline).

## Linters

**Shellcheck:**
```bash
shellcheck -s bash test/utils.sh
```
Ignores conftest.sh and selftest.sh (they have special formats).

**Hadolint:**
```bash
hadolint Dockerfile
```
Ignores rules: DL3003, DL3013, DL3041, DL4006

**Yamllint:**
```bash
yamllint .
```
Uses `.yamllint` config, ignores `/vendor`.

## Common Mistakes

| Problem | Fix |
|---------|-----|
| OPA coverage < 100% | Add test for every policy rule and helper function |
| BATS test fails "command not found" | Install prerequisites: jq, cosign, bats 1.8.2 |
| Shellcheck SC2086 | Quote variables: `"${var}"` not `$var` |
| OPA test "undefined ref" | Check import path matches test_data filename (no extension) |
| conftest.sh fails | Set `export POLICY_PATH=policies` before running |
