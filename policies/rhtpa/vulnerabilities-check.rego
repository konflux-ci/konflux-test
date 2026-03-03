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

# Collect unique CVE IDs across all sources for a given severity
rhtpa_unique_cve_ids(severity) := ids if {
  direct_ids := {issue.id |
    some source_name
    source := input.providers.rhtpa.sources[source_name]
    dep := source.dependencies[_]
    issue := dep.issues[_]
    issue.severity == severity
  }
  transitive_ids := {issue.id |
    some source_name
    source := input.providers.rhtpa.sources[source_name]
    dep := source.dependencies[_]
    tdep := dep.transitive[_]
    issue := tdep.issues[_]
    issue.severity == severity
  }
  ids := direct_ids | transitive_ids
}

# Concatenate per-source descriptions for a given severity
rhtpa_source_descriptions(severity) := desc if {
  descs := [d |
    some source_name
    source := input.providers.rhtpa.sources[source_name]
    direct := rhtpa_get_direct_vulns(source, severity)
    transitive := rhtpa_get_transitive_vulns(source, severity)
    all_vulns := array.concat(direct, transitive)
    count(all_vulns) > 0
    d := rhtpa_generate_description(source_name, direct, transitive)
  ]
  desc := concat("; ", descs)
}

default warn_rhtpa_critical_vulnerabilities := []

warn_rhtpa_critical_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}}] if {
  unique_ids := rhtpa_unique_cve_ids("CRITICAL")
  vulns_num := count(unique_ids)
  vulns_num > 0
  name := "rhtpa_critical_vulnerabilities"
  msg := sprintf("Found %d critical %s.", [vulns_num, rhtpa_pluralize(vulns_num)])
  description := rhtpa_source_descriptions("CRITICAL")
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

default warn_rhtpa_high_vulnerabilities := []

warn_rhtpa_high_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}}] if {
  unique_ids := rhtpa_unique_cve_ids("HIGH")
  vulns_num := count(unique_ids)
  vulns_num > 0
  name := "rhtpa_high_vulnerabilities"
  msg := sprintf("Found %d high %s.", [vulns_num, rhtpa_pluralize(vulns_num)])
  description := rhtpa_source_descriptions("HIGH")
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

default warn_rhtpa_medium_vulnerabilities := []

warn_rhtpa_medium_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}}] if {
  unique_ids := rhtpa_unique_cve_ids("MEDIUM")
  vulns_num := count(unique_ids)
  vulns_num > 0
  name := "rhtpa_medium_vulnerabilities"
  msg := sprintf("Found %d medium %s.", [vulns_num, rhtpa_pluralize(vulns_num)])
  description := rhtpa_source_descriptions("MEDIUM")
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

default warn_rhtpa_low_vulnerabilities := []

warn_rhtpa_low_vulnerabilities := [{"msg": msg, "vulnerabilities_number": vulns_num, "details": {"name": name, "description": description, "url": url}}] if {
  unique_ids := rhtpa_unique_cve_ids("LOW")
  vulns_num := count(unique_ids)
  vulns_num > 0
  name := "rhtpa_low_vulnerabilities"
  msg := sprintf("Found %d low %s.", [vulns_num, rhtpa_pluralize(vulns_num)])
  description := rhtpa_source_descriptions("LOW")
  url := "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}
