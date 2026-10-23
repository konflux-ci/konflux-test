# =============================================================================
# parse_acs_to_rhsa.jq
#
# Transforms a JSON ACS report into a RHSA-oriented map where:
#   - Critical and Important sections are present
#   - Found RHSAs are unique and attached in array
#
# USAGE:
#   jq -f parse_acs_to_rhsa.jq <acs-scan-output-file>.json
# =============================================================================

{
  "CRITICAL": [
    .[]
    | select(
        .severity == "CRITICAL_VULNERABILITY_SEVERITY"
        and (.advisory | length > 0)
      )
    | .advisory[]?.name
    | select(. != null)
  ] | unique,

  "IMPORTANT": [
    .[]
    | select(
        .severity == "IMPORTANT_VULNERABILITY_SEVERITY"
        and (.advisory | length > 0)
      )
    | .advisory[]?.name
    | select(. != null)
  ] | unique
}
