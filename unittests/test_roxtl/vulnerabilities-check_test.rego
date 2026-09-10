package required_checks

import future.keywords.if
import future.keywords.in

mock_input := {"roxctl_new": [
	{
		"cve": "CVE-2025-60753",
		"advisory": [
			{"name": "RHSA-2025:20936", "link": "https://access.redhat.com/errata/RHSA-2025:20936"},
			{"name": "RHSA-2025:20937", "link": "https://access.redhat.com/errata/RHSA-2025:20937"},
		],
		"summary": "A critical vulnerability in libarchive.",
		"links": ["https://access.redhat.com/security/cve/CVE-2025-60753"],
		"fixedBy": "0:3.5.3-6.el9_6",
		"severity": "CRITICAL_VULNERABILITY_SEVERITY",
		"components": [{"component": "libarchive", "version": "3.5.3-5.el9_6", "source": "var/lib/rpm"}],
	},
	{
		"cve": "CVE-2023-30571",
		"advisory": [],
		"summary": "An unpatched critical vulnerability in libarchive.",
		"links": ["https://access.redhat.com/security/cve/CVE-2023-30571"],
		"fixedBy": "",
		"severity": "CRITICAL_VULNERABILITY_SEVERITY",
		"components": [{"component": "libarchive", "version": "3.5.3-5.el9_6", "source": "var/lib/rpm"}],
	},
	{
		"cve": "CVE-2025-5914",
		"advisory": [{"name": "RHSA-2025:14130", "link": "https://access.redhat.com/errata/RHSA-2025:14130"}],
		"summary": "A high severity vulnerability in libarchive.",
		"links": ["https://access.redhat.com/security/cve/CVE-2025-5914"],
		"fixedBy": "0:3.5.3-6.el9_6",
		"severity": "IMPORTANT_VULNERABILITY_SEVERITY",
		"components": [{"component": "libarchive", "version": "3.5.3-5.el9_6", "source": "var/lib/rpm"}],
	},
	{
		"cve": "CVE-2024-12345",
		"advisory": [],
		"summary": "An unpatched high severity vulnerability affecting multiple components.",
		"links": ["https://access.redhat.com/security/cve/CVE-2024-12345"],
		"fixedBy": "",
		"severity": "IMPORTANT_VULNERABILITY_SEVERITY",
		"components": [
			{"component": "openssl-libs", "version": "3.0.7-27.el9", "source": "var/lib/rpm"},
			{"component": "openssl", "version": "3.0.7-27.el9", "source": "var/lib/rpm"},
		],
	},
	{
		"cve": "CVE-2024-33602",
		"advisory": [{"name": "RHSA-2024:5363", "link": "https://access.redhat.com/errata/RHSA-2024:5363"}],
		"summary": "A medium severity vulnerability in glibc.",
		"links": ["https://access.redhat.com/security/cve/CVE-2024-33602"],
		"fixedBy": "0:2.34-100.el9_4.4",
		"severity": "MODERATE_VULNERABILITY_SEVERITY",
		"components": [
			{"component": "glibc", "version": "2.34-100.el9_4.2", "source": "var/lib/rpm"},
			{"component": "glibc-common", "version": "2.34-100.el9_4.2", "source": "var/lib/rpm"},
		],
	},
	{
		"cve": "CVE-2021-20197",
		"advisory": [],
		"summary": "An unpatched medium severity vulnerability in binutils.",
		"links": ["https://access.redhat.com/security/cve/CVE-2021-20197"],
		"fixedBy": "",
		"severity": "MODERATE_VULNERABILITY_SEVERITY",
		"components": [{"component": "binutils", "version": "2.35.2-63.el9", "source": "var/lib/rpm"}],
	},
	{
		"cve": "CVE-2022-29458",
		"advisory": [{"name": "RHSA-2025:12876", "link": "https://access.redhat.com/errata/RHSA-2025:12876"}],
		"summary": "A low severity vulnerability in ncurses.",
		"links": ["https://access.redhat.com/security/cve/CVE-2022-29458"],
		"fixedBy": "0:6.2-10.20210508.el9_6.2",
		"severity": "LOW_VULNERABILITY_SEVERITY",
		"components": [
			{"component": "ncurses-base", "version": "6.2-10.20210508.el9", "source": "var/lib/rpm"},
			{"component": "ncurses-libs", "version": "6.2-10.20210508.el9", "source": "var/lib/rpm"},
		],
	},
	{
		"cve": "CVE-2021-3572",
		"advisory": [],
		"summary": "An unpatched low severity vulnerability in pip.",
		"links": ["https://access.redhat.com/security/cve/CVE-2021-3572"],
		"fixedBy": "",
		"severity": "LOW_VULNERABILITY_SEVERITY",
		"components": [{"component": "python3-pip-wheel", "version": "21.3.1-1.el9", "source": "var/lib/rpm"}],
	},
	{
		"cve": "CVE-2025-5918",
		"advisory": [],
		"summary": "A low severity vulnerability with no links.",
		"links": [],
		"fixedBy": "",
		"severity": "LOW_VULNERABILITY_SEVERITY",
		"components": [{"component": "libarchive1", "version": "3.5.3-5.el9_6", "source": "var/lib/rpm"}],
	},
	{
		"cve": "CVE-2025-5917",
		"advisory": [],
		"summary": "A low severity vulnerability with non-redhat link.",
		"links": ["https://nvd.nist.gov/vuln/detail/CVE-2025-5917"],
		"fixedBy": "",
		"severity": "LOW_VULNERABILITY_SEVERITY",
		"components": [{"component": "libarchive2", "version": "3.5.3-5.el9_6", "source": "var/lib/rpm"}],
	},
]}

empty_input := {"roxctl_new": []}

# ---------------------------------------------------------------------------
# Helper function unit tests
# ---------------------------------------------------------------------------

test_roxctl_has_rhsa_advisory_true if {
	roxctl_has_rhsa_advisory([{"name": "RHSA-2025:20936", "link": "x"}])
}

test_roxctl_has_rhsa_advisory_false if {
	not roxctl_has_rhsa_advisory([{"name": "SOME-OTHER-2025:1", "link": "x"}])
}

test_roxctl_has_redhat_link_true if {
	roxctl_has_redhat_link(["https://access.redhat.com/security/cve/CVE-2025-60753"])
}

test_roxctl_has_redhat_link_false if {
	not roxctl_has_redhat_link(["https://nvd.nist.gov/vuln/detail/CVE-2025-5917"])
}

test_roxctl_has_redhat_link_false_empty if {
	not roxctl_has_redhat_link([])
}

test_roxctl_count_vulnerabilities if {
	roxctl_count_vulnerabilities([{"cve": "CVE-1"}, {"cve": "CVE-2"}]) == 2
}

test_roxctl_count_vulnerabilities_empty if {
	roxctl_count_vulnerabilities([]) == 0
}

test_roxctl_format_components_single if {
	result := roxctl_format_components([{"component": "libarchive", "version": "3.5.3-5.el9_6", "source": "var/lib/rpm"}])
	result == "libarchive-3.5.3-5.el9_6@var/lib/rpm"
}

test_roxctl_format_components_multiple if {
	result := roxctl_format_components([
		{"component": "openssl-libs", "version": "3.0.7-27.el9", "source": "var/lib/rpm"},
		{"component": "openssl", "version": "3.0.7-27.el9", "source": "var/lib/rpm"},
	])
	result == "openssl-libs-3.0.7-27.el9@var/lib/rpm, openssl-3.0.7-27.el9@var/lib/rpm"
}

test_roxctl_generate_description if {
	vulns := [{"cve": "CVE-2025-60753", "components": [{"component": "libarchive", "version": "3.5.3-5.el9_6", "source": "var/lib/rpm"}]}]
	result := roxctl_generate_description(vulns)
	result == "Vulnerabilities found: CVE-2025-60753"
}

test_roxctl_get_patched_vulnerabilities if {
	result := roxctl_get_patched_vulnerabilities(mock_input.roxctl_new, "CRITICAL_VULNERABILITY_SEVERITY")
	count(result) == 1

	# entries now carry only cve + fixedBy -- "components" was removed
	result[0] == {"cve": "CVE-2025-60753", "fixedBy": "0:3.5.3-6.el9_6"}
}

test_roxctl_get_patched_vulnerabilities_none if {
	result := roxctl_get_patched_vulnerabilities(empty_input.roxctl_new, "CRITICAL_VULNERABILITY_SEVERITY")
	count(result) == 0
}

test_roxctl_get_unpatched_vulnerabilities if {
	result := roxctl_get_unpatched_vulnerabilities(mock_input.roxctl_new, "CRITICAL_VULNERABILITY_SEVERITY")
	count(result) == 1

	# entries now carry only cve -- "components" was removed
	result[0] == {"cve": "CVE-2023-30571"}
}

test_roxctl_get_unpatched_vulnerabilities_none if {
	result := roxctl_get_unpatched_vulnerabilities(empty_input.roxctl_new, "CRITICAL_VULNERABILITY_SEVERITY")
	count(result) == 0
}

test_roxctl_get_discrepancies if {
	result := roxctl_get_discrepancies(mock_input.roxctl_new)
	count(result) == 2

	# entries now carry only cve + links -- "components" was removed
	entries := {e.cve: e.links | e := result[_]}
	entries == {
		"CVE-2025-5918": [],
		"CVE-2025-5917": ["https://nvd.nist.gov/vuln/detail/CVE-2025-5917"],
	}
}

test_roxctl_get_discrepancies_none if {
	result := roxctl_get_discrepancies(empty_input.roxctl_new)
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_critical_vulnerabilities (patched critical)
# ---------------------------------------------------------------------------

test_warn_roxctl_critical_vulnerabilities if {
	result := warn_roxctl_critical_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 1
	result[0].details.name == "roxctl_critical_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2025-60753"
	result[0].details.url == "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

test_warn_roxctl_critical_vulnerabilities_none if {
	result := warn_roxctl_critical_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_unpatched_critical_vulnerabilities
# ---------------------------------------------------------------------------

test_warn_roxctl_unpatched_critical_vulnerabilities if {
	result := warn_roxctl_unpatched_critical_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 1
	result[0].details.name == "roxctl_unpatched_critical_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2023-30571"
}

test_warn_roxctl_unpatched_critical_vulnerabilities_none if {
	result := warn_roxctl_unpatched_critical_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_high_vulnerabilities (patched high)
# ---------------------------------------------------------------------------

test_warn_roxctl_high_vulnerabilities if {
	result := warn_roxctl_high_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 1
	result[0].details.name == "roxctl_high_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2025-5914"
}

test_warn_roxctl_high_vulnerabilities_none if {
	result := warn_roxctl_high_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_unpatched_high_vulnerabilities
# ---------------------------------------------------------------------------

test_warn_roxctl_unpatched_high_vulnerabilities if {
	result := warn_roxctl_unpatched_high_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 1
	result[0].details.name == "roxctl_unpatched_high_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2024-12345"
}

test_warn_roxctl_unpatched_high_vulnerabilities_none if {
	result := warn_roxctl_unpatched_high_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_medium_vulnerabilities (patched medium)
# ---------------------------------------------------------------------------

test_warn_roxctl_medium_vulnerabilities if {
	result := warn_roxctl_medium_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 1
	result[0].details.name == "roxctl_medium_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2024-33602"
}

test_warn_roxctl_medium_vulnerabilities_none if {
	result := warn_roxctl_medium_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_unpatched_medium_vulnerabilities
# ---------------------------------------------------------------------------

test_warn_roxctl_unpatched_medium_vulnerabilities if {
	result := warn_roxctl_unpatched_medium_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 1
	result[0].details.name == "roxctl_unpatched_medium_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2021-20197"
}

test_warn_roxctl_unpatched_medium_vulnerabilities_none if {
	result := warn_roxctl_unpatched_medium_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_low_vulnerabilities (patched low)
# ---------------------------------------------------------------------------

test_warn_roxctl_low_vulnerabilities if {
	result := warn_roxctl_low_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 1
	result[0].details.name == "roxctl_low_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2022-29458"
}

test_warn_roxctl_low_vulnerabilities_none if {
	result := warn_roxctl_low_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# warn_roxctl_unpatched_low_vulnerabilities
# ---------------------------------------------------------------------------

test_warn_roxctl_unpatched_low_vulnerabilities if {
	result := warn_roxctl_unpatched_low_vulnerabilities with input as mock_input
	count(result) == 1
	result[0].vulnerabilities_number == 3
	result[0].details.name == "roxctl_unpatched_low_vulnerabilities"

	result[0].details.description == "Vulnerabilities found: CVE-2021-3572, CVE-2025-5918, CVE-2025-5917"
}

test_warn_roxctl_unpatched_low_vulnerabilities_none if {
	result := warn_roxctl_unpatched_low_vulnerabilities with input as empty_input
	count(result) == 0
}

# ---------------------------------------------------------------------------
# discrepancies_for_cves
# ---------------------------------------------------------------------------

test_discrepancies_for_cves if {
	result := discrepancies_for_cves with input as mock_input
	count(result) == 1
	result[0].discrepancies_number == 2
	result[0].details.name == "discrepancies"

	result[0].details.description == "Vulnerabilities found: CVE-2025-5918, CVE-2025-5917"
	result[0].details.url == "https://access.redhat.com/articles/red_hat_vulnerability_tutorial"
}

test_discrepancies_for_cves_none if {
	result := discrepancies_for_cves with input as empty_input
	count(result) == 0
}
