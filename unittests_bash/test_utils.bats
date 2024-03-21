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

    skopeo() {
        if [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://valid-url" ]]; then
            echo '{"schemaVersion":2,"mediaType":"application/vnd.oci.image.index.v1+json","manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:f3d43a4e4e5371c9d972fa6a17144be940ddf3a3fd9185e2a4149a4c20e51e55","size":928,"platform":{"architecture":"amd64","os":"linux"}},{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:8e8229030a72efe300422eca38af80fae9b166361ae0f3ede8fb2fdad987f38f","size":928,"platform":{"architecture":"arm64","os":"linux"}}]}'
            return 0
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--config" && $4 == "docker://valid-image-manifest-url" ]]; then
            echo '{"architecture": "arm64"}'
            return 0
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://valid-image-manifest-url" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://valid-image-manifest-invalid-url"  ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "sha256:826def60fd1aa34f5090c9db60016773d91ecc324304d0ac3b01d","size": 14208}}'
        else
            echo 'Command execution failed'
            return 1
        fi
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
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"default","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: namespace" {
    run make_result_json -r SUCCESS -n testnamespace
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"testnamespace","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: note" {
    run make_result_json -r SUCCESS -t yolo
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"yolo","namespace":"default","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: sucesses" {
    run make_result_json -r SUCCESS -s 1
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"default","successes":1,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: failures" {
    run make_result_json -r SUCCESS -f 1
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"default","successes":0,"failures":1,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Result: warnings" {
    run make_result_json -r SUCCESS -w 1
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"default","successes":0,"failures":0,"warnings":1}'
    test_json_eq "${EXPECTED_JSON}" "${output}"
}

@test "Conftest input: successful tests" {
    TEST_OUTPUT=""
    parse_test_output testname conftest unittests_bash/data/conftest_successes.json
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"image_labels","successes":19,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${TEST_OUTPUT}"
}

@test "Conftest input: failed tests" {
    TEST_OUTPUT=""
    parse_test_output testname conftest unittests_bash/data/conftest_failures.json
    EXPECTED_JSON='{"result":"FAILURE","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"image_labels","successes":19,"failures":1,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${TEST_OUTPUT}"
}

@test "Conftest input: more than 1 result" {
    run parse_test_output testname conftest unittests_bash/data/conftest_multi.json
    [ "$status" -eq 1 ]
    [ "$output" = 'Cannot create test output, unexpected number of results in file: 2' ]
}

@test "Sarif input: successful tests" {
    TEST_OUTPUT=""
    parse_test_output testname sarif unittests_bash/data/sarif_successes.json
    EXPECTED_JSON='{"result":"SUCCESS","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"default","successes":0,"failures":0,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${TEST_OUTPUT}"
}

@test "Sarif input: failed tests" {
    TEST_OUTPUT=""
    parse_test_output testname sarif unittests_bash/data/sarif_failures.json
    EXPECTED_JSON='{"result":"FAILURE","timestamp":"whatever","note":"For details, check Tekton task log.","namespace":"default","successes":0,"failures":1,"warnings":0}'
    test_json_eq "${EXPECTED_JSON}" "${TEST_OUTPUT}"
}

@test "Get Image Index Manifests: missing IMAGE_URL" {
    run get_image_manifests
    [ "$status" -eq 2 ]
}

@test "Get Image Index Manifests: invalid-url" {
    run get_image_manifests -i invalid-url
    EXPECTED_RESPONSE='The image could not be inspected'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Image Index Manifests: success with raw flag" {
    run get_image_manifests -i valid-url
    EXPECTED_RESPONSE='{"amd64":"sha256:f3d43a4e4e5371c9d972fa6a17144be940ddf3a3fd9185e2a4149a4c20e51e55","arm64":"sha256:8e8229030a72efe300422eca38af80fae9b166361ae0f3ede8fb2fdad987f38f"}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Manifest Digest: success with raw flag" {
    run get_image_manifests -i valid-image-manifest-url
    EXPECTED_RESPONSE='{"arm64":"sha256:826def60fd1aa34f5090c9db60016773d91ecc324304d0ac3b01d"}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Manifest Digest: invalid-image-manifest-url" {
    run get_image_manifests -i invalid-image-manifest-url
    EXPECTED_RESPONSE='The image could not be inspected'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}
