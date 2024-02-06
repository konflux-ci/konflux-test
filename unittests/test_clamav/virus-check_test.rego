package required_checks

import future.keywords.in

import data.clamav_output as clamav


test_violation_infected_files {
    result := violation_infected_files with input as clamav
    result[_].msg == "Detected malware 'Win.Test.EICAR_HDB-1' in /tmp/test/eicar.txt"
}

test_warn_heuristic_malware_files {
    result := warn_heuristic_malware_files with input as clamav
    result[_].msg == "Detected potential malware 'Heuristics.Broken.Executable' by heuristics in /work/content/usr/lib/firmware/ath11k/IPQ5018/hw1.0/m3_fw.b00.xz"
}

