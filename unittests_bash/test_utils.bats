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
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://valid-image-manifest-url" ]]; then
            echo '{"Architecture": "arm64", "Digest": "sha256:826def60fd1aa34f5090c9db60016773d91ecc324304d0ac3b01d"}'
            return 0
        elif [[ $1 == "inspect" && $2 == "--config" && $3 == "docker://valid-image-manifest-url-2" ]]; then
            echo '{"config": {"Labels": {"architecture":"arm64"}}}'
            return 0
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://valid-image-manifest-url" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://invalid-image-manifest-url"  ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "sha256:826def60fd1aa34f5090c9db60016773d91ecc324304d0ac3b01d","size": 14208}}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://invalid-fragment-fbc" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://valid-fragment-fbc" ]]; then
            echo '{"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.12"}}'
            return 0
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://valid-fragment-fbc-success" ]]; then
            echo '{"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.15"}}'
            return 0
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://valid-fragment-fbc-success-2" ]]; then
            echo '{"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.20"}}'
            return 0
        else
            echo 'Unrecognized call to mock skopeo'
            return 1
        fi
    }

    opm() {
        if [[ $1 == "render" && $2 == "valid-fragment-fbc" || $1 == "render" && $2 == "valid-fragment-fbc-success" || $1 == "render" && $2 == "valid-fragment-fbc-success-2" ]]; then
            echo '{"invalid-control-char": "This is an invalid control char \\t", "schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha", "properties":[]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha", "properties":[]}'
            return 0
        elif [[ $1 == "render" && $2 == "valid-operator-bundle-1" ]]; then
            echo '{"schema":"olm.bundle", "relatedImages": [{"name": "", "image": "quay.io/securesign/rhtas-operator:something"}]}'
        elif [[ $1 == "render" && $2 == "registry.redhat.io/redhat/redhat-operator-index:v4.15" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@not-my-other-sha", "properties":[]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.io/random-index:v4.20" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha", "properties":[]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.redhat.io/redhat/redhat-operator-index:v4.12" ]]; then
            echo 'Invalid index'
            return 1
        else
            echo 'Invalid value'
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
    EXPECTED_RESPONSE='The raw image inspect command failed'
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
    EXPECTED_RESPONSE='The image manifest could not be inspected'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased Bundle: missing FBC_FRAGMENT" {
    run get_unreleased_bundle
    EXPECTED_RESPONSE='Missing parameter FBC_FRAGMENT'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get Unreleased Bundle: invalid-url" {
    run get_unreleased_bundle -i invalid-url
    EXPECTED_RESPONSE='Could not get ocp version for the fragment'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased Bundle: invalid-fragment-fbc" {
    run get_unreleased_bundle -i invalid-fragment-fbc
    EXPECTED_RESPONSE='Could not render image invalid-fragment-fbc'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased Bundle: valid-fragment-fbc and invalid index" {
    run get_unreleased_bundle -i valid-fragment-fbc
    EXPECTED_RESPONSE='Could not render image registry.redhat.io/redhat/redhat-operator-index:v4.12'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased Bundle: valid-fragment-fbc-success" {
    run get_unreleased_bundle -i valid-fragment-fbc-success
    EXPECTED_RESPONSE=$(echo "registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha registry.redhat.io/not-rhbk/operator-bundle@my-other-sha"  | tr ' ' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased Bundle: valid-fragment-fbc-success and index with tag" {
    run get_unreleased_bundle -i valid-fragment-fbc-success -b registry.redhat.io/redhat/redhat-operator-index:v4.27@randomsha256
    EXPECTED_RESPONSE=$(echo "registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha registry.redhat.io/not-rhbk/operator-bundle@my-other-sha"  | tr ' ' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased Bundle: valid-fragment-fbc-success-2 and custom index" {
    run get_unreleased_bundle -i valid-fragment-fbc-success-2 -b registry.io/random-index:v4.20
    EXPECTED_RESPONSE="registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Labels: valid-image-manifest-url-2" {
    run get_image_labels valid-image-manifest-url-2
    EXPECTED_RESPONSE="architecture=arm64"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Labels: missing image" {
    run get_image_labels
    EXPECTED_RESPONSE="Missing image pull spec"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get Image Labels: invalid-image-manifest-url" {
    run get_image_labels invalid-image-manifest-url
    EXPECTED_RESPONSE='Failed to inspect the image'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get relatedImages from operator bundle: valid-operator-bundle-1" {
    run extract_related_images_from_bundle valid-operator-bundle-1
    EXPECTED_RESPONSE="quay.io/securesign/rhtas-operator:something"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get relatedImages from operator bundle: missing image" {
    run extract_related_images_from_bundle
    EXPECTED_RESPONSE="Missing image pull spec"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get relatedImages from operator bundle: invalid-fragment-fbc" {
    run extract_related_images_from_bundle invalid-fragment-fbc
    EXPECTED_RESPONSE='Failed to render the image'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Process imageDigestMirrorSet: success" {
    yaml_input=$(cat <<EOF
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageDigestMirrorSet
metadata:
  name: example-mirror-set
spec:
  imageDigestMirrors:
    - mirrors:
        - quay.io/mirror-namespace/mirror-repo
        - other-registry.io/namespace/repo
      source: quay.io/gatekeeper/gatekeeper
EOF
)
    run process_image_digest_mirror_set "${yaml_input}"
    EXPECTED_RESPONSE="{\"quay.io/gatekeeper/gatekeeper\":[\"quay.io/mirror-namespace/mirror-repo\",\"other-registry.io/namespace/repo\"]}"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Process process_image_digest_mirror_set: invalid input" {
    run process_image_digest_mirror_set "\"invalid yaml"
    EXPECTED_RESPONSE="Invalid YAML input"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Replace image pullspec: invalid input" {
    run replace_image_pullspec "quay.io/some/image"
    EXPECTED_RESPONSE="Invalid input. Usage: replace_image_pullspec <image> <mirror>"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Replace image pullspec: success digest" {
    run replace_image_pullspec "registry.io/unavailable/pullspec@sha256:7441ff12e3d200521512247e053f5ed1c6157bc5f1cbe818dd3cc46903a1c72f" "quay.io/some/mirror"
    EXPECTED_RESPONSE="quay.io/some/mirror@sha256:7441ff12e3d200521512247e053f5ed1c6157bc5f1cbe818dd3cc46903a1c72f"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Replace image pullspec: success tag" {
    run replace_image_pullspec "registry.io/unavailable/pullspec:latest" "quay.io/some/mirror"
    EXPECTED_RESPONSE="quay.io/some/mirror:latest"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Replace image pullspec: success tag@sha256" {
    run replace_image_pullspec "registry.io/unavailable/pullspec:latest@sha256:7441ff12e3d200521512247e053f5ed1c6157bc5f1cbe818dd3cc46903a1c72f" "quay.io/some/mirror"
    EXPECTED_RESPONSE="quay.io/some/mirror:latest@sha256:7441ff12e3d200521512247e053f5ed1c6157bc5f1cbe818dd3cc46903a1c72f"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Replace image pullspec: invalid image format" {
    run replace_image_pullspec "registry.io/unavailable/pullspec@sha256:short-sha" "quay.io/some/mirror"
    EXPECTED_RESPONSE="Invalid pullspec format: registry.io/unavailable/pullspec@sha256:short-sha"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}
