package required_checks

import future.keywords.in
import future.keywords.if

violation_picklescan_infected_files := [{"msg": msg, "details": {"filename": filename, "finding": finding}} |
	some filename, finding in input.infected_files
	msg := sprintf("Dangerous global import found in '%s': %s", [filename, finding])
]
