package required_checks

import future.keywords.in

violation_infected_files[{"msg": msg, "details": {"filename": filename, "virname": virname, "description": description}}] {
	hit := _report.hits[_]

	filename := hit.filename
	virname := hit.virname
	msg := sprintf("Detected malware '%s' in %s", [virname, filename])
	description := "A malware has been found."

	not hit.is_heuristic # we don't want heursitics checks to cause false positive failures
}

warn_heuristic_malware_files[{"msg": msg, "details": {"filename": filename, "virname": virname, "description": description}}] {
	hit := _report.hits[_]

	filename := hit.filename
	virname := hit.virname
	msg := sprintf("Detected potential malware '%s' by heuristics in %s", [virname, filename])
	description := "The heuristic check detected a potential malware. (Heuristic checks have higher possibility of false positive results.)"

	hit.is_heuristic # we want to only warn for heuristic checks
}

_report := d {
	marker := "----------- SCAN SUMMARY -----------"
	marker_parts := split(input.output, marker)
	hits_lines := split(marker_parts[0], "\n")
	summary_lines := split(marker_parts[1], "\n")

	summary := {key: value |
		some line in summary_lines
		parts := split(line, ":")
		raw_key := parts[0]
		raw_value := concat(":", array.slice(parts, 1, count(parts)))

		key := replace(lower(trim(raw_key, " ")), " ", "_")
		value := trim(raw_value, " ")

		key != ""
	}

	hits := [{"filename": filename, "virname": virname, "is_heuristic": is_heuristic} |
		some hit in hits_lines
		regex.match("^\\S+: \\S+ FOUND$", hit)

		hit_parts := split(hit, " ")
		filename := substring(hit_parts[0], 0, count(hit_parts[0]) - 1)
		virname := hit_parts[1]
		is_heuristic := startswith(virname, "Heuristics.") # malware has been detected by heuristics and could be false positive
	]

	d := object.union(summary, {"hits": hits})
}
