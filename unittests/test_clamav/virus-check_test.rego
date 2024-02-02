package required_checks

import future.keywords.in

import data.clamav_output as clamav


test_violation_infected_files {
    result := violation_infected_files with input as clamav
    expected_msgs := {
        "Infected file: /tmp/test/eicar.txt: Win.Test.EICAR_HDB-1 FOUND",
        "Infected file: /work/content/usr/lib/firmware/ath11k/IPQ5018/hw1.0/m3_fw.b00.xz: Heuristics.Broken.Executable FOUND"
    }
    msgs := { res.msg |
        some res in result
    }
    expected_msgs == msgs
}

