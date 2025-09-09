package required_checks

import future.keywords.in
import future.keywords.if

import data.clamav_output as clamav


test_violation_infected_files if {
    result := violation_infected_files with input as clamav
    result[_].msg == "Detected malware 'Win.Test.EICAR_HDB-1' in /tmp/test/eicar.txt"
}

test_warn_heuristic_malware_files if {
    result := warn_heuristic_malware_files with input as clamav
    result[0].msg == "Detected potential malware 'Heuristics.Limits.Exceeded.MaxFileSize' by heuristics in /tmp/giant-file.a"
    result[1].msg == "Detected potential malware 'Heuristics.Limits.Exceeded.MaxFileSize' by heuristics in /tmp/giant.db"
    result[2].msg == "Detected potential malware 'Heuristics.Broken.Executable' by heuristics in /work/content/usr/lib/firmware/ath11k/IPQ5018/hw1.0/m3_fw.b00.xz"
}
