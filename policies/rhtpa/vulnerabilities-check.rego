package required_checks

import future.keywords.if

# Get direct vulnerabilities of a given severity from a source
rhtpa_get_direct_vulns(source, severity) := vulns if {
  vulns := [{"ref": dep.ref, "issues": filtered} |
    dep := source.dependencies[_]
    filtered := [issue | issue := dep.issues[_]; issue.severity == severity]
    count(filtered) > 0
  ]
}

# Get transitive vulnerabilities of a given severity from a source.
# Transitive dependencies are indirect dependencies pulled in by a direct
# dependency (e.g. if the image depends on A and A depends on B, then B is
# transitive). Each transitive entry is tracked with its parent_ref so the
# description can show the dependency chain.
rhtpa_get_transitive_vulns(source, severity) := vulns if {
  vulns := [{"ref": tdep.ref, "parent_ref": dep.ref, "issues": filtered} |
    dep := source.dependencies[_]
    tdep := dep.transitive[_]
    filtered := [issue | issue := tdep.issues[_]; issue.severity == severity]
    count(filtered) > 0
  ]
}

# Count total issues across vulnerability entries
rhtpa_count_vulns(vulns) := cnt if {
  cnt := sum([count(v.issues) | v := vulns[_]])
}

# Format description string from direct and transitive vulnerability entries
rhtpa_generate_description(source_name, direct, transitive) := dsc if {
  direct_descs := [sprintf("%s [direct] (%s)", [v.ref, concat(", ", [i.id | i := v.issues[_]])]) | v := direct[_]]
  transitive_descs := [sprintf("%s [transitive via %s] (%s)", [v.ref, v.parent_ref, concat(", ", [i.id | i := v.issues[_]])]) | v := transitive[_]]
  all_descs := array.concat(direct_descs, transitive_descs)
  dsc := sprintf("Source: %s. Affected dependencies: %s", [source_name, concat(", ", all_descs)])
}

# Pluralize "vulnerability"
rhtpa_pluralize(n) = "vulnerability" { n == 1 }
rhtpa_pluralize(n) = "vulnerabilities" { n != 1 }

warn_rhtpa_critical_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  some source_name
  source := input.providers.rhtpa.sources[source_name]

  direct := rhtpa_get_direct_vulns(source, "CRITICAL")
  transitive := rhtpa_get_transitive_vulns(source, "CRITICAL")
  all_vulns := array.concat(direct, transitive)
  not count(all_vulns) == 0

  name := "rhtpa_critical_vulnerabilities"
  vulns_num := rhtpa_count_vulns(all_vulns)
  msg := sprintf("Found %d critical %s from source %s.", [vulns_num, rhtpa_pluralize(vulns_num), source_name])
  description := rhtpa_generate_description(source_name, direct, transitive)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_rhtpa_high_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  some source_name
  source := input.providers.rhtpa.sources[source_name]

  direct := rhtpa_get_direct_vulns(source, "HIGH")
  transitive := rhtpa_get_transitive_vulns(source, "HIGH")
  all_vulns := array.concat(direct, transitive)
  not count(all_vulns) == 0

  name := "rhtpa_high_vulnerabilities"
  vulns_num := rhtpa_count_vulns(all_vulns)
  msg := sprintf("Found %d high %s from source %s.", [vulns_num, rhtpa_pluralize(vulns_num), source_name])
  description := rhtpa_generate_description(source_name, direct, transitive)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_rhtpa_medium_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  some source_name
  source := input.providers.rhtpa.sources[source_name]

  direct := rhtpa_get_direct_vulns(source, "MEDIUM")
  transitive := rhtpa_get_transitive_vulns(source, "MEDIUM")
  all_vulns := array.concat(direct, transitive)
  not count(all_vulns) == 0

  name := "rhtpa_medium_vulnerabilities"
  vulns_num := rhtpa_count_vulns(all_vulns)
  msg := sprintf("Found %d medium %s from source %s.", [vulns_num, rhtpa_pluralize(vulns_num), source_name])
  description := rhtpa_generate_description(source_name, direct, transitive)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]

warn_rhtpa_low_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}} |
  some source_name
  source := input.providers.rhtpa.sources[source_name]

  direct := rhtpa_get_direct_vulns(source, "LOW")
  transitive := rhtpa_get_transitive_vulns(source, "LOW")
  all_vulns := array.concat(direct, transitive)
  not count(all_vulns) == 0

  name := "rhtpa_low_vulnerabilities"
  vulns_num := rhtpa_count_vulns(all_vulns)
  msg := sprintf("Found %d low %s from source %s.", [vulns_num, rhtpa_pluralize(vulns_num), source_name])
  description := rhtpa_generate_description(source_name, direct, transitive)
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
]
