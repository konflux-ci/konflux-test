# =============================================================================
# parse_to_cve_oriented_output.jq
#
# Transforms a JSON vulnerability report into a CVE-oriented list where:
#   - Every CVE is unique
#   - All distinct source links are preserved in a "links" array
#   - Every affected component entry carries its filesystem location
#
# USAGE:
#   jq -s -f parse_to_cve_oriented_output.jq vulns-with-cves.json
#
# OUTPUT SCHEMA (per entry):
#   {
#     "cve":      string,
#     "advisory"  [string, ...]
#     "summary":  string,          # from the highest-severity occurrence
#     "links":    [string, ...],   # ALL distinct links across occurrences, sorted
#     "fixedBy":  string,          # from the highest-severity occurrence
#     "severity": string,          # highest severity across all occurrences
#     "components": [
#       {
#         "component": string,
#         "version":   string,
#         "location":  string      # filesystem path from the component record
#       },
#       ...                        # deduplicated by (component, version), sorted
#     ]
#   }
#
# DEDUP STRATEGY:
#   Scalar CVE fields (summary, fixedBy, severity) come from the entry with
#   the highest severity rank:
#     CRITICAL_VULNERABILITY_SEVERITY   → 4
#     IMPORTANT_VULNERABILITY_SEVERITY  → 3
#     MODERATE_VULNERABILITY_SEVERITY   → 2
#     LOW_VULNERABILITY_SEVERITY        → 1
#     (absent / unknown)                → 0
#
#   links      — union of all distinct non-empty link values, sorted
#   components — union of all distinct (component, version) pairs with their
#                location, sorted by component::version
# =============================================================================

# ---------------------------------------------------------------------------
# Helper: severity string → numeric rank
# ---------------------------------------------------------------------------
def severity_rank:
  if   . == "CRITICAL_VULNERABILITY_SEVERITY"  then 4
  elif . == "IMPORTANT_VULNERABILITY_SEVERITY" then 3
  elif . == "MODERATE_VULNERABILITY_SEVERITY"  then 2
  elif . == "LOW_VULNERABILITY_SEVERITY"        then 1
  else 0
  end;

# ---------------------------------------------------------------------------
# Step 1 – Flatten: one record per (vuln × component), carrying location
# ---------------------------------------------------------------------------
[ .[].scan.components[]
  | . as $comp
  | .vulns[]?
  | select(.cve != null and .cve != "")
  | {
      cve:       .cve,
      advisory:  (.advisory // ""),
      summary:   (.summary  // ""),
      link:      (.link     // ""),
      fixedBy:   (.fixedBy  // ""),
      severity:  (.severity // ""),
      component: $comp.name,
      version:   ($comp.version // ""),
      source:  ($comp.location // "")
    }
]

# ---------------------------------------------------------------------------
# Step 2 – Group by CVE ID
# ---------------------------------------------------------------------------
| group_by(.cve)

# ---------------------------------------------------------------------------
# Step 3 – Merge each group into a single CVE object
# ---------------------------------------------------------------------------
| [ .[]
    | . as $group

    # a) Best record for scalar fields: highest severity rank, first entry wins ties
    | ( $group | sort_by(.severity | severity_rank) | reverse | .[0] ) as $best

    # b) links: collect all non-empty link values, deduplicate, sort
    | ( $group
        | map(.link)
        | map(select(. != null and . != ""))
        | unique
        | sort
      ) as $links
    # c) advisory: collect all non-empty advisories, deduplicate, sort
    | ( $group
        | map(.advisory)
        | map(select(. != null and . != ""))
        | unique
        | sort
      ) as $advisory
    # d) components: deduplicate by (component, version), carry source, sort
    | ( $group
        | map({ component, version, source })
        | unique_by(.component + "::" + .version)
        | sort_by(.component + "::" + .version)
      ) as $components

    | {
        cve:        $best.cve,
        advisory:   $advisory,
        summary:    $best.summary,
        links:      $links,
        fixedBy:    $best.fixedBy,
        severity:   $best.severity,
        components: $components
      }
  ]

# ---------------------------------------------------------------------------
# Step 4 – Sort final list alphabetically by CVE ID
# ---------------------------------------------------------------------------
| sort_by(.cve)
