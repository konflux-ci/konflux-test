package required_checks

import future.keywords.if
import future.keywords.in

# Severity mapping for roxctl (CVE-oriented format)
# CRITICAL_VULNERABILITY_SEVERITY -> Critical
# IMPORTANT_VULNERABILITY_SEVERITY -> High
# MODERATE_VULNERABILITY_SEVERITY -> Medium
# LOW_VULNERABILITY_SEVERITY -> Low

roxctl_has_rhsa_advisory(advisories) if {
  some a in advisories
  contains(a.name, "RHSA")
}

roxctl_get_patched_vulnerabilities(input_data, severity) := vulnerabilities if {
  vulnerabilities := [entry |
    v := input_data[_]
    v.severity == severity
    v.fixedBy != ""
    count(v.advisory) > 0
    roxctl_has_rhsa_advisory(v.advisory)
    entry := {"cve": v.cve, "components": v.components, "fixedBy": v.fixedBy}
  ]
}

roxctl_get_unpatched_vulnerabilities(input_data, severity) := vulnerabilities if {
  vulnerabilities := [entry |
    v := input_data[_]
    v.severity == severity
    v.fixedBy == ""
    count(v.advisory) == 0
    entry := {"cve": v.cve, "components": v.components}
  ]
}

roxctl_get_discrepancies(input_data) := disc if {
  disc := [entry |
    v := input_data[_]
    v.severity != ""
    not roxctl_has_redhat_link(v.links)
    entry := {"cve": v.cve, "components": v.components, "links": v.links}
  ]
}

roxctl_has_redhat_link(links) if {
  some link in links
  contains(link, "redhat")
}

roxctl_count_vulnerabilities(vulnerabilities) := count(vulnerabilities)

roxctl_format_components(components) := formatted if {
  formatted := concat(", ", [sprintf("%s-%s@%s", [c.component, c.version, c.source]) | c := components[_]])
}

roxctl_generate_description(vulnerabilities) := dsc if {
  dsc := sprintf("Vulnerabilities found: %s", [concat(", ",
    [sprintf("%s: %s", [v.cve, roxctl_format_components(v.components)]) | v := vulnerabilities[_]]
  )])
}


warn_roxctl_critical_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_critical_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "CRITICAL_VULNERABILITY_SEVERITY")
  not count(components_with_critical_vulnerabilities) == 0

  name := "roxctl_critical_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_critical_vulnerabilities)
  msg := "Found components with critical vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_critical_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_critical_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_critical_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "CRITICAL_VULNERABILITY_SEVERITY")
  not count(components_with_unpatched_critical_vulnerabilities) == 0

  name := "roxctl_unpatched_critical_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_critical_vulnerabilities)
  msg := "Found components with unpatched critical vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_critical_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_high_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_high_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "IMPORTANT_VULNERABILITY_SEVERITY")
  not count(components_with_high_vulnerabilities) == 0

  name := "roxctl_high_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_high_vulnerabilities)
  msg := "Found components with high vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_high_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_high_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_high_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "IMPORTANT_VULNERABILITY_SEVERITY")
  not count(components_with_unpatched_high_vulnerabilities) == 0

  name := "roxctl_unpatched_high_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_high_vulnerabilities)
  msg := "Found components with unpatched high vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_high_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_medium_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_medium_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "MODERATE_VULNERABILITY_SEVERITY")
  not count(components_with_medium_vulnerabilities) == 0

  name := "roxctl_medium_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_medium_vulnerabilities)
  msg := "Found components with medium vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_medium_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_medium_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_medium_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "MODERATE_VULNERABILITY_SEVERITY")
  not count(components_with_unpatched_medium_vulnerabilities) == 0

  name := "roxctl_unpatched_medium_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_medium_vulnerabilities)
  msg := "Found components with unpatched medium vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_medium_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_low_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_low_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "LOW_VULNERABILITY_SEVERITY")
  not count(components_with_low_vulnerabilities) == 0

  name := "roxctl_low_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_low_vulnerabilities)
  msg := "Found components with low vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_low_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_low_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_low_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "LOW_VULNERABILITY_SEVERITY")
  not count(components_with_unpatched_low_vulnerabilities) == 0

  name := "roxctl_unpatched_low_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_low_vulnerabilities)
  msg := "Found components with unpatched low vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_low_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

discrepancies_for_cves := [{"msg": msg, "discrepancies_number": disc_num, "details": {"name": name, "description": description, "url": url}} |
  cves_with_discrepancies := roxctl_get_discrepancies(input)
  not count(cves_with_discrepancies) == 0

  name := "discrepancies"
  disc_num := roxctl_count_vulnerabilities(cves_with_discrepancies)
  msg := "Found cves with discrepancies."
  description := roxctl_generate_description(cves_with_discrepancies)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]
