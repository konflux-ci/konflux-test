---
name: ci-cd-quirks
description: Use when CI checks fail unexpectedly, when preparing code for CI, or when encountering non-obvious build and pipeline behavior. Covers hermetic builds, Tekton pipelines, multi-arch, GitHub Actions checks, and integration test structure.
---

# CI/CD Quirks and Gotchas

## Overview

CI runs on both GitHub Actions (linting, unit tests) and Konflux Tekton pipelines (image builds, integration tests). Several non-obvious requirements trip up developers.

## When to Use

- CI failed and the error is unclear
- Preparing a change that touches dependencies, policies, or the Dockerfile
- Understanding build pipeline behavior
- Debugging integration test failures

## GitHub Actions Checks

**File:** `.github/workflows/pr-checks.yaml`

| Check | What it does | Strict enforcement |
|-------|-------------|------------|
| yamllint | Lints all YAML files | Yes, fails PR |
| hadolint | Lints Dockerfile (ignores DL3003,DL3013,DL3041,DL4006) | Yes, fails PR |
| opa_policies_unittest | OPA tests + coverage check (**100% coverage required** — fails if any line uncovered) | Yes, fails PR |
| bash_unittests | BATS tests for bash functions | Yes, fails PR |
| shellcheck | Bash linting on `test/` (ignores conftest.sh, selftest.sh) | Yes, fails PR |
| gitlint | Validates commit message format | PR-only, enforces lowercase after colon (custom rule UC1) |

**Critical detail:** OPA coverage enforcement uses jq to assert:
```bash
jq -j -r 'if .coverage < 100 then "ERROR: Code coverage threshold not met: got \(.coverage) instead of 100.00\n" | halt_error(1) else "" end'
```

## Tekton Build Pipeline

**PR Pipeline:** `.tekton/konflux-test-pull-request.yaml`
- Hermetic build (network-isolated, dependencies prefetched via Cachi2)
- Multi-arch: builds for amd64 and arm64
- Image tag: `on-pr-{{revision}}`
- Expires after 5 days, max 3 kept
- Cancel-in-progress: only one PR pipeline per PR at a time

**Push Pipeline:** `.tekton/konflux-test-push.yaml`
- Regular build + security scans
- Image tag: `{{revision}}`
- Triggered on merge to main

## Integration Test Pipeline

**File:** `integration-tests/konflux_test_validation.yaml`

Runs INSIDE the built image after build succeeds:

1. **test-metadata** — Extract image URL, git revision
2. **shellcheck** — Lints shell scripts (excludes conftest.sh, selftest.sh)
3. **hadolint** — Lints Dockerfile
4. **self-test** — Runs `/selftest.sh` (smoke tests: binaries present, conftest works)
5. **opa-policy-unittests** — Runs `opa test` on ./policies (100% coverage enforced)
6. **bats-unit-tests** — Runs `bats unittests_bash` (expects cosign in `/usr/local/bin`)

Output format: Uses Tekton result functions (`make_result_json`, `parse_test_output`, `handle_error`).

## Hermetic Build Constraints

All dependencies must be pre-declared — no network access during build:

**RPM packages:** `rpms.in.yaml` → `rpms.lock.yaml` (generated lockfile)
```yaml
packages:
  - jq
  - python3
  - skopeo
```

**Generic artifacts:** `artifacts.lock.yaml` (binaries, tarballs)
```yaml
- download_url: https://github.com/operator-framework/operator-registry/releases/download/v1.57.0/linux-amd64-opm.tar.gz
  checksum: sha256:abc123...
  filename: opm-v1.57.0.tar.gz
```

**Critical:** Hermetic build requires **both amd64 and arm64 variants** for each multi-arch binary.

Dockerfile uses:
```bash
if [ "$TARGETARCH" = "amd64" ]; then
    cp ${PATH_TO_ART}/opm-amd64 /usr/local/bin/opm
elif [ "$TARGETARCH" = "arm64" ]; then
    cp ${PATH_TO_ART}/opm-arm64 /usr/local/bin/opm
fi
```

## Common Mistakes

| Problem | Root cause | Fix |
|---------|-----------|-----|
| OPA coverage exactly 99.x% | CI enforces **100%** strictly | Add test for uncovered policy line |
| `shellcheck` passes locally, fails CI | Different flags (`-s bash` in CI) | Run locally with: `shellcheck -s bash test/utils.sh` |
| Binary "not found" after build | Missing from `artifacts.lock.yaml` | Add both amd64 and arm64 variants with checksums |
| Integration tests fail but unit tests pass | Tests run inside the image | Check Dockerfile COPY paths and selftest.sh validation |
| Hadolint fails on new instruction | Rule not in ignore list | Check `.github/workflows/pr-checks.yaml` for `ignore:` field |
| New RPM package fails hermetic build | Not declared in rpms.in.yaml | Add package name and regenerate rpms.lock.yaml |
