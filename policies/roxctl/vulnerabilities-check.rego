package required_checks

import future.keywords.if

# Severity mapping for roxctl
# CRITICAL -> Critical
# IMPORTANT -> High  
# MODERATE -> Medium
# LOW -> Low

# Function to get components with vulnerabilities of specific severity that have fixes
roxctl_get_patched_vulnerabilities(input_data, severity) := vulnerabilities if {
  vulnerabilities := [{"name": v.componentName, "version": v.componentVersion, "vulnerabilities": vuln} |
    v := input_data.result.vulnerabilities[_]
    vuln := {v.cveId | v.cveSeverity == severity; v.componentFixedVersion != ""; contains(v.advisoryId,"RHSA")}
    count(vuln) > 0
  ]
}

# Function to get components with vulnerabilities of specific severity without fixes
roxctl_get_unpatched_vulnerabilities(input_data, severity) := vulnerabilities if {
  vulnerabilities := [{"name": v.componentName, "version": v.componentVersion, "vulnerabilities": vuln} |
    v := input_data.result.vulnerabilities[_]
    vuln := {v.cveId | v.cveSeverity == severity; v.componentFixedVersion == ""; not contains(v.advisoryId,"RHSA")}
    count(vuln) > 0
  ]
}

# Function returns count of all vulnerabilities
roxctl_count_vulnerabilities(vulnerabilities) := cnt if {
  cnt := sum([count(v.vulnerabilities) | v := vulnerabilities[_]])
}

# Function generates description with components and their vulnerabilities
roxctl_generate_description(vulnerabilities) := dsc if {
  dsc := sprintf("Vulnerabilities found: %s", [concat(", ",
                  [sprintf("%s-%s@%s (%s)", [v.name, v.version, v.location, concat(", ", v.vulnerabilities)]) | v := vulnerabilities[_]]
                )])
}


warn_roxctl_critical_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_critical_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "CRITICAL")
  not count(components_with_critical_vulnerabilities) == 0

  name := "roxctl_critical_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_critical_vulnerabilities)
  msg := "Found components with critical vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_critical_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_critical_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_critical_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "CRITICAL")
  not count(components_with_unpatched_critical_vulnerabilities) == 0

  name := "roxctl_unpatched_critical_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_critical_vulnerabilities)
  msg := "Found components with unpatched critical vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_critical_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_high_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_high_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "IMPORTANT")
  not count(components_with_high_vulnerabilities) == 0

  name := "roxctl_high_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_high_vulnerabilities)
  msg := "Found components with high vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_high_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_high_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_high_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "IMPORTANT")
  not count(components_with_unpatched_high_vulnerabilities) == 0

  name := "roxctl_unpatched_high_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_high_vulnerabilities)
  msg := "Found components with unpatched high vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_high_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_medium_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_medium_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "MODERATE")
  not count(components_with_medium_vulnerabilities) == 0

  name := "roxctl_medium_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_medium_vulnerabilities)
  msg := "Found components with medium vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_medium_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_medium_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_medium_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "MODERATE")
  not count(components_with_unpatched_medium_vulnerabilities) == 0

  name := "roxctl_unpatched_medium_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_medium_vulnerabilities)
  msg := "Found components with unpatched medium vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_medium_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_low_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_low_vulnerabilities := roxctl_get_patched_vulnerabilities(input, "LOW")
  not count(components_with_low_vulnerabilities) == 0

  name := "roxctl_low_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_low_vulnerabilities)
  msg := "Found components with low vulnerabilities that have available fixes. Consider updating to a newer version of those components."
  description := roxctl_generate_description(components_with_low_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_roxctl_unpatched_low_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  components_with_unpatched_low_vulnerabilities := roxctl_get_unpatched_vulnerabilities(input, "LOW")
  not count(components_with_unpatched_low_vulnerabilities) == 0

  name := "roxctl_unpatched_low_vulnerabilities"
  vulns_num := roxctl_count_vulnerabilities(components_with_unpatched_low_vulnerabilities)
  msg := "Found components with unpatched low vulnerabilities. These vulnerabilities don't have a known fix at this time."
  description := roxctl_generate_description(components_with_unpatched_low_vulnerabilities)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]
