---
name: adding-tools-to-image
description: Use when adding new tools, binaries, or packages to the konflux-test container image. Covers artifacts.lock.yaml (generic binaries), rpms.in.yaml (system packages), multi-architecture support, and hermetic build constraints.
---

# Adding Tools to the Image

## Overview

The konflux-test container image contains 40+ tools and binaries for Konflux CI Tekton tasks. Adding a new tool requires updates to three files due to hermetic build constraints and multi-architecture support.

## When to Use

- Adding a new binary/utility to the image
- Adding a system package via dnf
- Updating tool versions
- Supporting a new architecture

## Quick Reference

| Dependency type | Declaration file | Lockfile | Dockerfile |
|--------|----------|----------|-----------|
| System packages (RPM) | `rpms.in.yaml` | `rpms.lock.yaml` | `dnf install ...` |
| Binaries/artifacts | `artifacts.lock.yaml` | N/A | `COPY ${PATH_TO_ART}/...` |

## Adding an RPM Package

1. **Edit `rpms.in.yaml`** — add package name to the `packages:` list
2. **Regenerate lockfile** — cachi2 generates `rpms.lock.yaml` with pinned versions and checksums
3. **Edit `Dockerfile`** — add `dnf install` command in the build stage
4. **Verify in CI** — CI validates the package installs correctly in hermetic build

**Example:**
```yaml
# rpms.in.yaml
packages:
  - jq
  - python3
  - new-package-name  # Add here
```

## Adding a Binary/Artifact

1. **Get download URL and checksum** (sha256) for both architectures
2. **Edit `artifacts.lock.yaml`** — add entry with URL, checksum, filename for amd64 AND arm64
3. **Edit `Dockerfile`** — add conditional COPY with `$TARGETARCH` logic
4. **Verify in CI** — CI builds for both architectures

**Example:**
```yaml
# artifacts.lock.yaml
- download_url: https://github.com/owner/repo/releases/download/v1.2.0/tool-linux-amd64.tar.gz
  checksum: sha256:abc123def456...
  filename: tool-amd64.tar.gz
- download_url: https://github.com/owner/repo/releases/download/v1.2.0/tool-linux-arm64.tar.gz
  checksum: sha256:def456abc123...
  filename: tool-arm64.tar.gz
```

**Dockerfile pattern:**
```dockerfile
FROM ubi9/ubi:9.7 AS final

ARG TARGETARCH

RUN if [ "$TARGETARCH" = "amd64" ]; then \
      cp ${PATH_TO_ART}/tool-amd64.tar.gz /tmp/ && \
      tar xzf /tmp/tool-amd64.tar.gz -C /usr/local/bin; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      cp ${PATH_TO_ART}/tool-arm64.tar.gz /tmp/ && \
      tar xzf /tmp/tool-arm64.tar.gz -C /usr/local/bin; \
    fi
```

The `PATH_TO_ART` variable is set by hermetic build system (=/cachi2/output/deps/generic).

## Hermetic Build Constraints

**Critical:** All dependencies must be declared BEFORE build starts — no network access during build.

- **RPM packages:** declared in `rpms.in.yaml`, locked in `rpms.lock.yaml`
- **Generic artifacts:** declared in `artifacts.lock.yaml` with checksums
- **Cachi2:** prefetches all dependencies offline before build
- **Multi-arch:** every binary must have both amd64 and arm64 variants with separate checksums

If a tool is missing from either lockfile, the hermetic build will fail: `ERROR: dependency not found`.

## Multi-Architecture Support

The build system uses `TARGETARCH` (set by buildkit) to select architecture-specific binaries:

```dockerfile
ARG TARGETARCH
RUN if [ "$TARGETARCH" = "amd64" ]; then copy-amd64; \
    elif [ "$TARGETARCH" = "arm64" ]; then copy-arm64; \
    fi
```

**Every multi-arch binary in `artifacts.lock.yaml` needs BOTH amd64 and arm64 entries with separate checksums.**

## Multiple Versions

Tools like opm are intentionally installed at multiple versions for backwards compatibility with different OCP versions (v1.26.4 through v1.57.0). Each version is a separate artifact entry.

## Validating the Tool

After adding a tool, `test/selftest.sh` should validate:

1. Binary is present and executable
2. Binary returns expected version/help output
3. Binary works correctly in integration tests

Add a validation check to `test/selftest.sh`:

```bash
if ! command -v new-tool &> /dev/null; then
    echo "ERROR: new-tool not found in image"
    exit 1
fi
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing from artifacts.lock.yaml | Add entry with download_url, checksum, filename (both arches) |
| Only amd64 variant, missing arm64 | Every binary needs both variants with separate checksums |
| Wrong checksum format | Use `sha256:` prefix and full hash (not abbreviated) |
| Dockerfile COPY wrong path | Use `${PATH_TO_ART}/filename` (=/cachi2/output/deps/generic) |
| Dockerfile forgot $TARGETARCH condition | Both amd64 and arm64 builds will fail with "file not found" |
| Tool not validated in selftest.sh | Add `command -v tool` check and version validation |
