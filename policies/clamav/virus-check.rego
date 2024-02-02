package required_checks

import future.keywords.in

violation_infected_files[{"msg": msg, "details": {"name": name, "description": description}}] {
	hit := _report.hits[_]

	name := hit
	msg := sprintf("Infected file: %s", [hit])
	description := "A malware has been found"
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

	hits := [hit |
		some hit in hits_lines
		regex.match("^\\S+: \\S+ FOUND$", hit)
	]

	d := object.union(summary, {"hits": hits})
}
