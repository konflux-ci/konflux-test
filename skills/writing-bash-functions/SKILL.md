---
name: writing-bash-functions
description: Use when adding or modifying bash utility functions in test/utils.sh. Covers naming conventions, function structure, BATS tests, mock patterns for external tools, TEST_OUTPUT format, and shellcheck compliance.
---

# Writing Bash Functions

## Overview

Bash utility functions in `test/utils.sh` support Tekton task steps by handling image parsing, scanning output parsing, OPM operations, Pyxis API calls, and Tekton result formatting. File contains 100+ functions across 2000+ lines.

## When to Use

- Adding new functions to test/utils.sh
- Writing BATS tests in unittests_bash/
- Understanding mock patterns for skopeo/opm
- Debugging shellcheck failures

## Quick Reference

| Item | Location/Convention |
|------|-------------------|
| Main functions file | `test/utils.sh` |
| BATS test files | `unittests_bash/test_utils.bats`, `unittests_bash/test_cosign.bats` |
| Test data fixtures | `unittests_bash/data/*.json` |
| Integration tests | `test/conftest.sh` (separate BATS file) |

## Function Naming Conventions

| Prefix | Purpose | Example |
|--------|---------|---------|
| `get_` | Retrieve/extract a value | `get_image_labels()`, `get_base_image()` |
| `extract_` | Parse complex data | `extract_unique_bundles_from_catalog()` |
| `parse_` | Transform format | `parse_image_url()`, `parse_test_output()` |
| `handle_` | Error handling | `handle_error()`, `handle_pyxis_response_pages()` |
| `make_` | Construct output | `make_result_json()` |
| `validate_` | Check conditions | `validate_ocp_version()` |
| `replace_` | Substitute values | `replace_image_pullspec()` |

## Function Structure Pattern

```bash
function_name() {
    # Parameter validation
    if [ -z "$1" ]; then
        echo "ERROR: parameter required" >&2
        exit 2
    fi
    
    local result="$1"
    # Use local for all variables
    
    # Return via echo -n (no trailing newline for JSON)
    echo -n "$result"
}
```

**Exit codes:** 0=success, 1=error, 2=parameter error, 3=format error

## Tekton Result Functions

Three critical output functions consumed by Tekton:

| Function | Purpose | Output format |
|----------|---------|----------------|
| `make_result_json` | Format Tekton task result | JSON with name, value, type |
| `parse_test_output` | Convert conftest/sarif JSON to TEST_OUTPUT | Structured JSON with result, timestamp, note, namespace |
| `handle_error` | Trap and report errors | Tekton error result with structured message |

See `test/utils.sh` for full implementations.

## Writing BATS Tests

**File:** `unittests_bash/test_{name}.bats`

```bash
#!/usr/bin/env bats

setup() {
    source test/utils.sh
    
    # Mock external tools as bash functions
    skopeo() {
        if [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/image@digest" ]]; then
            echo '{"Name": "image", "Architecture": "amd64"}'
        fi
    }
    
    export -f skopeo
}

@test "get_image_labels returns labels" {
    run get_image_labels "registry/image@digest"
    [ "$status" -eq 0 ]
    [ "$output" != "" ]
}
```

**Patterns:**
- `@test "description" { ... }` — BATS test format
- `run function_name args` — Execute and capture result
- `[ "$status" -eq 0 ]` — Assert exit code
- `test_json_eq expected_json output_json` — Compare JSON (ignores timestamps)
- `export -f mock_function` — Export mock function to subshells

## Mock Pattern: skopeo

Skopeo is mocked in `setup()` as a bash function with if-elif branches:

```bash
skopeo() {
    if [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://image@digest" ]]; then
        echo '{"schemaVersion": 2, ...}'
    elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://image@digest" ]]; then
        echo '{"Name": "image", ...}'
    fi
}
```

Add new elif branches for each new image reference you test.

## Test Data Fixtures

JSON/YAML files in `unittests_bash/data/` used as mock API responses:

- `conftest_failures.json` — conftest output with violations
- `conftest_successes.json` — conftest output with no violations
- `sarif_failures.json` — SARIF format vulnerability data
- Test data sourced via `@test` context or as function arguments

## Shellcheck Compliance

Run before pushing:
```bash
shellcheck -s bash test/utils.sh
```

**Common violations:**
- SC2086: Quote variables: `"${var}"` not `$var`
- SC2181: Check exit code of specific command, not $?
- SC2119: Function called without args but expects them

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing `local` keyword | All function-local variables must use `local` |
| Using `echo` instead of `echo -n` | Trailing newline breaks JSON piping to jq |
| Not mocking external tools | setup() must override skopeo, opm, cosign as functions |
| Wrong test data path | File `unittests_bash/data/conftest_failures.json` sourced in test |
| Shellcheck violation | Run `shellcheck -s bash test/utils.sh` before pushing |
| Not exporting mock function | Use `export -f function_name` so subshells see the mock |
