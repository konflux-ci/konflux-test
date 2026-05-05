package required_checks

import future.keywords.if

import data.picklescan_output as picklescan

test_violation_picklescan_infected_files if {
	result := violation_picklescan_infected_files with input as picklescan
	count(result) == 2
	result[_].msg == "Dangerous global import found in 'file1.pkl': global import 'os.system' FOUND"
	result[_].msg == "Dangerous global import found in 'file2.pkl': global import 'eval' FOUND"
}

test_no_violation_clean_scan if {
	result := violation_picklescan_infected_files with input as {
		"infected_files": {},
		"summary": {"scanned_files": 5, "infected_files": 0, "dangerous_globals": 0},
	}
	count(result) == 0
}
