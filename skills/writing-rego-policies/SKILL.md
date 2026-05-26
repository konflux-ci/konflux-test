---
name: writing-rego-policies
description: Use when writing, modifying, or reviewing OPA/conftest Rego policies. Covers package naming, rule prefixes (violation_ and warn_), conftest namespaces, violation object structures, imports, and unit test patterns.
---

# Writing Rego Policies

## Overview

Policies in `policies/{scanner}/` validate structured outputs from Tekton security scanners using OPA and conftest. Each policy is a Rego package that generates violations or warnings based on input data from scanners like Clair, ClamAV, PickleScan, Roxctl, and RHTPA.

## When to Use

- Writing a new Rego policy for a new scanner or check
- Modifying existing policy logic
- Understanding conftest namespace organization
- Writing unit tests for policies

## Quick Reference

| Item | Convention |
|------|-----------|
| Policy location | `policies/{scanner}/{check-name}.rego` |
| Test location | `unittests/test_{scanner}/{check-name}_test.rego` |
| Test data | `unittests/test_data/{scanner}.json` or `.yaml` |
| Package names | `required_checks`, `optional_checks`, or `fbc_checks` |
| Rule prefixes | `violation_*` (failures), `warn_*` (warnings) |
| Conftest invocation | `conftest test ... --namespace required_checks` |

## Package Names and Conftest Namespaces

Policies use three package names, selected via `--namespace` flag:

| Package | Namespace flag | Purpose | Example |
|---------|---|---------|---------|
| `required_checks` | `--namespace required_checks` | Blocking policies, must pass | clair, roxctl, picklescan, image/required-labels |
| `optional_checks` | `--namespace optional_checks` | Advisory warnings | image/inherited-labels, image/optional-labels |
| `fbc_checks` | `--namespace fbc_checks` | FBC (File-Based Catalog) specific | image/fbc-labels |

A single `.rego` file contains exactly ONE package name.

## Rule Naming Prefixes

| Prefix | Conftest result | Use when |
|--------|-----------------|----------|
| `violation_` | Failure (blocks image) | Check must pass for image acceptance (most policies) |
| `warn_` | Warning (informational) | Check is advisory and doesn't block |
| `deny_` | Failure | Alternative prefix (not used in current policies) |

## Violation/Warning Object Structures

**Rules must return a LIST** (list comprehension `[{...} | ...]`), never a single object.

Structures vary by policy type:

### Vulnerability Scanning (clair, rhtpa, roxctl warn rules)
```rego
[{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}}]
```

### Label/Image Checks (image/*)
```rego
[{"msg": msg, "details": {"name": name, "description": description, "url": url}}]
```
(No `vulnerabilities_number` field)

### Virus Scanning (clamav, picklescan)
```rego
[{"msg": msg, "details": {"filename": filename, "virname": virname, "description": description}}]
```
(ClamAV); or `{"filename": filename, "finding": finding}` (PickleScan)

### Roxctl Discrepancies
```rego
[{"msg": msg, "discrepancies_number": disc_num, "details": {"name": name, "description": description, "url": url}}]
```

## Helper Function Patterns

Vulnerability policies typically define:
```rego
get_patched_vulnerabilities(input_data, severity) := vulnerabilities if { ... }
get_unpatched_vulnerabilities(input_data, severity) := vulnerabilities if { ... }
count_vulnerabilities(vulnerabilities) := cnt if { ... }
generate_description(vulnerabilities) := dsc if { ... }
```

Then use these in rule definitions. See `policies/clair/vulnerabilities-check.rego` for full pattern.

## Imports

**NOT all policies use imports.** Add imports only when needed:

| Import | Use when |
|--------|----------|
| `import future.keywords.if` | Using `if` keyword in rule definitions |
| `import future.keywords.in` | Using `in` operator for membership checks |
| `import data as base_image` | Accessing other data packages (rare) |

Label/image policies typically have **no imports**.

## Default Values

Use `default` to safely return empty arrays when data is absent:
```rego
default warn_critical_vulnerabilities := []
```

Only used in `policies/rhtpa/vulnerabilities-check.rego`.

## Writing Unit Tests

Same package as policy, in `unittests/test_{scanner}/{check-name}_test.rego`:

```rego
package required_checks

import data.clair as clair
import future.keywords.if

test_warn_critical_vulnerabilities if {
    result := warn_critical_vulnerabilities with input as clair
    result[_].details.name == "clair_critical_vulnerabilities"
    result[_].vulnerabilities_number == 1
}
```

**Patterns:**
- Import test data as `import data.{fixture_name} as {alias}`
- Test function name: `test_{rule_name}`
- Inject data: `with input as fixture_alias`
- Assert on `.details.name`, `.vulnerabilities_number`, `.msg`
- Test clean input: `rule_name == [] with input as clean_data`

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Wrong package name | Must match conftest `--namespace` flag exactly |
| Returning single object instead of list | Rules must be list comprehensions: `[{...} \| ...]` |
| Wrong detail object keys | Use correct keys for policy type (see structures above) |
| Test data import wrong | File `unittests/test_data/clair.json` → `import data.clair as clair` |
| Missing test for empty input | Add negative test: `rule == [] with input as empty_data` |
| Using `if` without importing | Add `import future.keywords.if` |
