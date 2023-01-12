#!/usr/bin/env bats

setup() {
    source test/utils.sh

    DEBUG=0

    test_json_eq() {
        EXPECTED=$1
        OUTPUT=$2
        # do not compare timestamps, they differs ofc
        if [ ${DEBUG} -ne 0 ]; then echo "# C1=$1" >&3; fi
        if [ ${DEBUG} -ne 0 ]; then echo "# C2=$2" >&3; fi
        C1=$( echo "${EXPECTED}" | jq 'del(.timestamp)' | jq -Sc)
        C2=$( echo "${OUTPUT}" | jq 'del(.timestamp)' | jq -Sc)
        [ "${C1}" = "${C2}" ]
    }
}

@test "Result: missing result" {
    run make_result_json
    [ "$status" -eq 2 ]
}

@test "Result: invalid result" {
    run make_result_json -r INVALID
    [ "$status" -eq 2 ]
}

@test "Result: default" {
    run make_result_json -r SUCCESS
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"default","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: namespace" {
    run make_result_json -r SUCCESS -n testnamespace
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"testnamespace","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: note" {
    run make_result_json -r SUCCESS -t yolo
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"yolo","namespace":"default","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: sucesses" {
    run make_result_json -r SUCCESS -s 1
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"default","successes":1,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: failures" {
    run make_result_json -r SUCCESS -f 1
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"default","successes":0,"failures":1,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: warnings" {
    run make_result_json -r SUCCESS -w 1
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"default","successes":0,"failures":0,"warnings":1}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Error result: default" {
    run make_error_result_json "Something is wrong" "testnamespace"
    EXPECTED_JSON='{"result":"ERROR","timestamp":"whatever","note":"Something is wrong","namespace":"testnamespace","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Conftest input: successful tests" {
    HACBS_TEST_OUTPUT=""
    parse_hacbs_test_output testname conftest unittests_bash/data/conftest_successes.json
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"image_labels","successes":19,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${HACBS_TEST_OUTPUT}"
}

@test "Conftest input: failed tests" {
    HACBS_TEST_OUTPUT=""
    parse_hacbs_test_output testname conftest unittests_bash/data/conftest_failures.json
    EXPECTED_JSON='{"result":"FAILURE","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"image_labels","successes":19,"failures":1,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${HACBS_TEST_OUTPUT}"
}

@test "Sarif input: successful tests" {
    HACBS_TEST_OUTPUT=""
    parse_hacbs_test_output testname sarif unittests_bash/data/sarif_successes.json
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"default","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${HACBS_TEST_OUTPUT}"
}

@test "Sarif input: failed tests" {
    HACBS_TEST_OUTPUT=""
    parse_hacbs_test_output testname sarif unittests_bash/data/sarif_failures.json
    EXPECTED_JSON='{"result":"FAILURE","timestamp":"whatever","note":"For more details please visit the logs in workspace of Tekton tasks.","namespace":"default","successes":0,"failures":1,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${HACBS_TEST_OUTPUT}"
}
