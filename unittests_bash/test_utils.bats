#!/usr/bin/env bats

setup() {
    source test/utils.sh
    OPM_RENDER_CACHE=$(mktemp -d)

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
        # The --raw inspects return the OCI metadata for the image references. This includes the mediaType, manifests (for image indexes),
        # digests and their platforms, and annotations.
        # The non-raw skopeo inspect returns information about the image. This is primarily used to get the digest and architecture of an image from its OCI Image Manifest.

        # registry/image@valid-url
        if [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image@valid-url" ]]; then
            echo '{"schemaVersion":2,"mediaType":"application/vnd.oci.image.index.v1+json","manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"valid-manifest-amd64","size":928,"platform":{"architecture":"amd64","os":"linux"}},{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"valid-manifest-arm64","size":928,"platform":{"architecture":"arm64","os":"linux"}}]}'

        # registry/image@valid-manifest-amd64
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/image@valid-manifest-amd64" || $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@invalid" || $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@valid-manifest-amd64" ]]; then
            echo '{"Name": "valid-manifest-amd64", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-manifest-amd64", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image@valid-manifest-amd64" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@invalid" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@valid-manifest-amd64" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-manifest-amd64","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.12"}}'

        # registry/image-manifest@valid-labels
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/image-manifest@valid-labels" ]]; then
            echo '{"Name": "valid-labels", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-labels", "Os": "linux"}'

        # registry/image-manifest@valid
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image-manifest@valid" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image-manifest@invalid" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-manifest-amd64","size": 14208}}'
        
        # registry/image-manifest@valid-oci
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image-manifest@valid-oci" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image-manifest@valid-oci" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-manifest-amd64","size": 14208}}'

        # registry/fbc-fragment@valid-success
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@valid-success" ]]; then
            echo '{"Name": "valid-success", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-success", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@valid-success" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-success","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.15", "org.opencontainers.image.base.digest": "boo"}}'

        # registry/fbc-fragment@valid-success-2
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@valid-success-2" ]]; then
            echo '{"Name": "valid-success-2", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-success-2", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@valid-success-2" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-success-2","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.20"}}'

        # registry/fbc-fragment@isolated
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@isolated" ]]; then
            echo '{"Name": "isolated", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "isolated", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@isolated" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "isolated","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.15"}}'
        
        # Some skopeo commands fail
        else
            echo 'Unrecognized call to mock skopeo'
            return 1
        fi
    }

    opm() {
        if [[ $1 == "render" && $2 == "registry/fbc-fragment:tag@valid-manifest-amd64" || $1 == "render" && $2 == "registry/fbc-fragment:tag@valid-success" || $1 == "render" && $2 == "registry/fbc-fragment:tag@valid-success-2" ]]; then
            echo '{"invalid-control-char": "This is an invalid control char \\t", "schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha", "properties":[], "relatedImages": [{"name": "foo-bar", "image": "registry.redhat.io/foo/bar@sha256:my-bar-sha"}, {"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha", "properties":[], "relatedImages": [{"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry/fbc-fragment@valid-success" ]]; then
            echo '{"invalid-control-char": "This is an invalid control char \\t", "schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha", "properties":[], "relatedImages": []}'
        elif [[ $1 == "render" && $2 == "registry/fbc-fragment:tag@isolated" ]]; then
            echo '{"invalid-control-char": "This is an invalid control char \\t", "schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha", "properties":[], "relatedImages": [{"name": "foo-bar", "image": "registry.redhat.io/foo/bar@sha256:my-bar-sha"}, {"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}'
        elif [[ $1 == "render" && $2 == "valid-operator-bundle-1" ]]; then
            echo '{"schema":"olm.bundle", "relatedImages": [{"name": "", "image": "quay.io/securesign/rhtas-operator:something"},{"name": "", "image": "valid-operator-bundle-1"}]}'
        elif [[ $1 == "render" && $2 == "registry.redhat.io/redhat/redhat-operator-index:v4.15" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[], "relatedImages": [{"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@not-my-other-sha", "properties":[], "relatedImages": [{"name": "foo-baz", "image": "registry.redhat.io/foo/bar@sha256:my-bar-sha"}]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.io/random-index:v4.15" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[], "relatedImages": [{"name": "foo-bar", "image": "registry.redhat.io/foo/bar@sha256:my-bar-sha"}, {"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha", "properties":[]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.io/random-index:v4.20" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha", "properties":[]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.io/random-index-2:v4.20" ]]; then
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

teardown() {
    rm -rf $OPM_RENDER_CACHE
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

@test "Parse image url: missing parameter" {
    run parse_image_url
    EXPECTED_RESPONSE="parse_image_url: Missing positional parameter \$1 (image url)"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Parse image url: multiple at" {
    run parse_image_url foo@sha@sha
    EXPECTED_RESPONSE='parse_image_url: foo@sha@sha does not match the format registry(:port)/repository(:tag)(@digest)'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 3 ]]
}

@test "Parse image url: multiple tags" {
    run parse_image_url registry:port/foo:bar:bar
    EXPECTED_RESPONSE='parse_image_url: registry:port/foo:bar:bar does not match the format registry(:port)/repository(:tag)(@digest)'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 3 ]]
}

@test "Get image repository: repository" {
    run get_image_registry_and_repository foo
    EXPECTED_RESPONSE='foo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository: repository, tag, and digest" {
    run get_image_registry_and_repository foo:bar@digest
    EXPECTED_RESPONSE='foo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and tag: repository" {
    run get_image_registry_repository_tag foo
    EXPECTED_RESPONSE='foo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and tag: repository and tag" {
    run get_image_registry_repository_tag foo:bar
    EXPECTED_RESPONSE='foo:bar'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and tag: repository and digest" {
    run get_image_registry_repository_tag foo@digest
    EXPECTED_RESPONSE='foo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and tag: repository, tag, and digest" {
    run get_image_registry_repository_tag foo:bar@digest
    EXPECTED_RESPONSE='foo:bar'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and digest: repository" {
    run get_image_registry_repository_digest foo
    EXPECTED_RESPONSE='foo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and digest: repository and tag" {
    run get_image_registry_repository_digest foo:bar
    EXPECTED_RESPONSE='foo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and digest: repository and digest" {
    run get_image_registry_repository_digest foo@digest
    EXPECTED_RESPONSE='foo@digest'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository and digest: repository, tag, and digest" {
    run get_image_registry_repository_digest foo:bar@digest
    EXPECTED_RESPONSE='foo@digest'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository, tag, and digest: repository" {
    run get_image_registry_repository_tag_digest foo
    EXPECTED_RESPONSE='foo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository, tag, and digest: repository and tag" {
    run get_image_registry_repository_tag_digest foo:bar
    EXPECTED_RESPONSE='foo:bar'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository, tag, and digest: repository and digest" {
    run get_image_registry_repository_tag_digest foo@digest
    EXPECTED_RESPONSE='foo@digest'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image repository, tag, and digest: repository, tag, and digest" {
    run get_image_registry_repository_tag_digest foo:bar@digest
    EXPECTED_RESPONSE='foo:bar@digest'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get base image: registry/image@valid-url" {
    run get_base_image registry/image@valid-url
    EXPECTED_RESPONSE='registry.redhat.io/openshift4/ose-operator-registry:v4.12'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get base image: registry/fbc-fragment@valid-success" {
    run get_base_image registry/fbc-fragment@valid-success
    EXPECTED_RESPONSE='registry.redhat.io/openshift4/ose-operator-registry:v4.15@boo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get OCP version from fragment: registry/fbc-fragment@valid-success" {
    run get_ocp_version_from_fbc_fragment registry/fbc-fragment@valid-success
    EXPECTED_RESPONSE='v4.15'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get matching catalog image from fragment: registry/fbc-fragment@valid-success" {
    run get_target_fbc_catalog_image -i registry/fbc-fragment@valid-success -b registry.redhat.io/openshift4/ose-operator-registry
    EXPECTED_RESPONSE='registry.redhat.io/openshift4/ose-operator-registry:v4.15'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get matching catalog image from fragment: registry/fbc-fragment@valid-success default index" {
    run get_target_fbc_catalog_image -i registry/fbc-fragment@valid-success
    EXPECTED_RESPONSE='registry.redhat.io/redhat/redhat-operator-index:v4.15'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Index Manifests: missing IMAGE_URL" {
    run get_image_manifests
    [ "$status" -eq 2 ]
}

@test "Get Image Index Manifests: registry/image:tag@invalid-url" {
    run get_image_manifests -i registry/image:tag@invalid-url
    EXPECTED_RESPONSE='get_image_manifests: The raw image inspect command failed'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Image Index Manifests: success with raw flag" {
    run get_image_manifests -i registry/image:tag@valid-url
    EXPECTED_RESPONSE='{"amd64":"valid-manifest-amd64","arm64":"valid-manifest-arm64"}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Manifest Digest: success with raw flag" {
    run get_image_manifests -i registry/image:tag@valid-manifest-amd64
    EXPECTED_RESPONSE='{"amd64":"valid-manifest-amd64"}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Manifest Digest: registry/image-manifest:tag@invalid" {
    # This will pass the --raw inspection but will fail when the raw isn't used. It just checks the
    # error case of the skopeo command not working. This check would not be likely to fail in use.
    run get_image_manifests -i registry/image-manifest:tag@invalid
    EXPECTED_RESPONSE='get_image_manifests: The image manifest could not be inspected'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Image Manifest OCI: registry/image-manifest:tag@valid-oci" {
    # This inspection passes but there is no architecture or digest when
    # performing a non-raw inspect
    run get_image_manifests -i registry/image-manifest:tag@valid-oci
    EXPECTED_RESPONSE='get_image_manifests: The image manifest could not be inspected'
}

@test "Get Unreleased Bundle: missing FBC_FRAGMENT" {
    run get_unreleased_bundles
    EXPECTED_RESPONSE="get_unreleased_bundles: missing keyword parameter (-i FBC_FRAGMENT)"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get Unreleased Bundle: registry/image:tag@valid-url" {
    run get_unreleased_bundles -i registry/image:tag@valid-url
    EXPECTED_RESPONSE=$(echo "render_opm: could not render catalog registry/image:tag@valid-url*extract_differential_fbc_metadata: could not render FBC fragment registry/image:tag@valid-url"  | tr '*' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased Bundle: registry/fbc-fragment:tag@invalid" {
    run get_unreleased_bundles -i registry/fbc-fragment:tag@invalid
    EXPECTED_RESPONSE=$(echo "render_opm: could not render catalog registry/fbc-fragment:tag@invalid*extract_differential_fbc_metadata: could not render FBC fragment registry/fbc-fragment:tag@invalid"  | tr '*' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased Bundle: valid FBC fragment and invalid index" {
    run get_unreleased_bundles -i registry/fbc-fragment:tag@valid-manifest-amd64
    EXPECTED_RESPONSE=$(echo "render_opm: could not render catalog registry.redhat.io/redhat/redhat-operator-index:v4.12*extract_differential_fbc_metadata: could not render index image registry.redhat.io/redhat/redhat-operator-index:v4.12"  | tr '*' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased Bundle: registry/fbc-fragment:tag@valid-success" {
    run get_unreleased_bundles -i registry/fbc-fragment:tag@valid-success
    echo "$output"
    EXPECTED_RESPONSE=$(echo "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha"  | tr ' ' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased Bundle: registry/fbc-fragment:tag@valid-success and index with tag" {
    run get_unreleased_bundles -i registry/fbc-fragment:tag@valid-success -b registry.redhat.io/redhat/redhat-operator-index:v4.15@randomsha256
    EXPECTED_RESPONSE=$(echo "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha"  | tr ' ' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased Bundle: registry/fbc-fragment:tag@valid-success-2 and custom index" {
    run get_unreleased_bundles -i registry/fbc-fragment:tag@valid-success-2 -b registry.io/random-index:v4.20
    EXPECTED_RESPONSE="registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased FBC related images: missing FBC_FRAGMENT" {
    run get_unreleased_fbc_related_images
    EXPECTED_RESPONSE='get_unreleased_fbc_related_images: missing keyword parameter (-i FBC_FRAGMENT)'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get Unreleased FBC related images: registry/image:tag@invalid-url" {
    run get_unreleased_fbc_related_images -i registry/image:tag@invalid-url
    EXPECTED_RESPONSE=$(echo "render_opm: could not render catalog registry/image:tag@invalid-url*extract_differential_fbc_metadata: could not render FBC fragment registry/image:tag@invalid-url"  | tr '*' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased FBC related images: registry/fbc-fragment:tag@invalid" {
    run get_unreleased_fbc_related_images -i registry/fbc-fragment:tag@invalid
    EXPECTED_RESPONSE=$(echo "render_opm: could not render catalog registry/fbc-fragment:tag@invalid*extract_differential_fbc_metadata: could not render FBC fragment registry/fbc-fragment:tag@invalid"  | tr '*' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased FBC related images: registry/fbc-fragment:tag@valid-url and invalid index" {
    run get_unreleased_fbc_related_images -i registry/fbc-fragment:tag@valid-url
    EXPECTED_RESPONSE=$(echo "render_opm: could not render catalog registry/fbc-fragment:tag@valid-url*extract_differential_fbc_metadata: could not render FBC fragment registry/fbc-fragment:tag@valid-url"  | tr '*' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get Unreleased FBC related images: registry/fbc-fragment:tag@isolated and missing index" {
    run get_unreleased_fbc_related_images -i registry/fbc-fragment:tag@isolated
    EXPECTED_RESPONSE=$(echo "[\"registry.redhat.io/foo/bar@sha256:my-bar-sha\"]" | tr ' ' '\n' | tr '*' ' ')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased FBC related images: registry/fbc-fragment:tag@isolated and index with tag" {
    run get_unreleased_fbc_related_images -i registry/fbc-fragment:tag@isolated -b registry.redhat.io/redhat/redhat-operator-index:v4.15@randomsha256
    EXPECTED_RESPONSE=$(echo "[\"registry.redhat.io/foo/bar@sha256:my-bar-sha\"]" | tr ' ' '\n' | tr '*' ' ')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased FBC related images: registry/fbc-fragment:tag@isolated and custom index" {
    run get_unreleased_fbc_related_images -i registry/fbc-fragment:tag@isolated -b registry.io/random-index:v4.20
    EXPECTED_RESPONSE="[]"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Unreleased FBC related images: registry/fbc-fragment@valid-success and no related images" {
    run get_unreleased_fbc_related_images -i registry/fbc-fragment@valid-success -b registry.io/random-index:v4.20
    EXPECTED_RESPONSE="[]"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Labels: registry/image-manifest:tag@valid-labels" {
    run get_image_labels registry/image-manifest:tag@valid-labels
    EXPECTED_RESPONSE=$(echo "architecture=arm64 name=my-image" | tr ' ' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Labels: missing image" {
    run get_image_labels
    EXPECTED_RESPONSE="get_image_labels: missing positional parameter \$1 (image pull spec)"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get Image Labels: registry/image-manifest:tag@invalid" {
    run get_image_labels registry/image-manifest:tag@invalid
    EXPECTED_RESPONSE='get_image_labels: failed to inspect the image'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get relatedImages from operator bundle: valid-operator-bundle-1" {
    run extract_related_images_from_bundle valid-operator-bundle-1
    EXPECTED_RESPONSE="quay.io/securesign/rhtas-operator:something"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get relatedImages from operator bundle: missing image" {
    run extract_related_images_from_bundle
    EXPECTED_RESPONSE="extract_related_images_from_bundle: missing positional parameter \$1 (image pull spec)"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get relatedImages from operator bundle: registry/fbc-fragment:tag@invalid" {
    run extract_related_images_from_bundle registry/fbc-fragment:tag@invalid
    EXPECTED_RESPONSE=$(echo "render_opm: could not render catalog registry/fbc-fragment:tag@invalid*extract_related_images_from_bundle: failed to render the image registry/fbc-fragment:tag@invalid"  | tr '*' '\n')
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
    EXPECTED_RESPONSE="process_image_digest_mirror_set: Invalid YAML input"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Replace image pullspec: invalid input" {
    run replace_image_pullspec "quay.io/some/image"
    EXPECTED_RESPONSE="replace_image_pullspec: Usage: replace_image_pullspec <image> <mirror>"
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
    EXPECTED_RESPONSE="replace_image_pullspec: invalid pullspec format: registry.io/unavailable/pullspec@sha256:short-sha"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get package from catalog: success single package" {
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged",
    "defaultChannel": "stable"
}
EOF
)
    run get_package_from_catalog "${RENDER_OUT_FBC}"
    EXPECTED_RESPONSE="kubevirt-hyperconverged"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get package from catalog: success multiple packages" {
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged-v1",
    "defaultChannel": "stable"
}
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged-v2",
    "defaultChannel": "dev-preview"
}
{
    "schema": "olm.channel",
    "name": "dev-preview",
    "package": "kubevirt-hyperconverged-v2",
    "entries": [
        {
            "name": "kubevirt-hyperconverged-operator.v4.99.0-0.1723448771"
        }
    ]
}
{
    "schema": "olm.channel",
    "name": "stable",
    "package": "kubevirt-hyperconverged-v1",
    "entries": [
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.3"
        },
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.4"
        }
    ]
}
{
    "schema": "olm.channel",
    "name": "dev-preview-2",
    "package": "kubevirt-hyperconverged-v2",
    "entries": [
        {
            "name": "kubevirt-hyperconverged-operator.v5.00.0-0.1723448771"
        }
    ]
}
EOF
)
    run get_package_from_catalog "${RENDER_OUT_FBC}"
    EXPECTED_RESPONSE="kubevirt-hyperconverged-v2"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get package from catalog: missing image" {
    run get_package_from_catalog
    EXPECTED_RESPONSE="get_package_from_catalog: Missing 'opm render' output for the image"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get channel from catalog: success" {
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged",
    "defaultChannel": "stable"
}
EOF
)
    PACKAGE_NAME="kubevirt-hyperconverged"
    run get_channel_from_catalog "${RENDER_OUT_FBC}" "${PACKAGE_NAME}"
    EXPECTED_RESPONSE="stable"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get channel from catalog: failure, package not found" {
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged",
    "defaultChannel": "stable"
}
EOF
)
    PACKAGE_NAME="kubevirt"
    run get_channel_from_catalog "${RENDER_OUT_FBC}" "${PACKAGE_NAME}"
    EXPECTED_RESPONSE="get_channel_from_catalog: Package name kubevirt not found in the rendered FBC"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get channel from catalog: failure, invalid input" {
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged",
    "defaultChannel": "stable"
}
EOF
)
    run get_channel_from_catalog "${RENDER_OUT_FBC}"
    EXPECTED_RESPONSE="get_channel_from_catalog: Invalid input. Usage: get_channel_from_catalog <RENDER_OUT_FBC> <PACKAGE_NAME>"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get highest bundle version from catalog: success" {
    PACKAGE_NAME="kubevirt-hyperconverged-v1"
    CHANNEL_NAME="stable"
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged-v1",
    "defaultChannel": "stable"
}
{
    "schema": "olm.channel",
    "name": "stable",
    "package": "kubevirt-hyperconverged-v1",
    "entries": [
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.3"
        },
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.4"
        },
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.5"
        }
    ]
}
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.17.5",
    "package": "kubevirt-hyperconverged-v1",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db",
    "properties": []
}
EOF
)
    run get_highest_bundle_version "${RENDER_OUT_FBC}" "${PACKAGE_NAME}" "${CHANNEL_NAME}"
    EXPECTED_RESPONSE="registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get highest bundle version from catalog: missing image" {
    PACKAGE_NAME="kubevirt-hyperconverged-v1"
    CHANNEL_NAME="stable"
    run get_highest_bundle_version "${PACKAGE_NAME}" "${CHANNEL_NAME}"
    EXPECTED_RESPONSE="get_highest_bundle_version: Invalid input. Usage: get_highest_bundle_version <RENDER_OUT_FBC> <PACKAGE_NAME> <CHANNEL_NAME>"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get highest bundle version from catalog: no bundle found" {
    PACKAGE_NAME="kubevirt-hyperconverged"
    CHANNEL_NAME="stable"
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged-v1",
    "defaultChannel": "stable"
}
{
    "schema": "olm.channel",
    "name": "stable",
    "package": "kubevirt-hyperconverged-v1",
    "entries": [
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.3"
        },
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.4"
        },
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.5"
        }
    ]
}
EOF
)
    run get_highest_bundle_version "${RENDER_OUT_FBC}" "${PACKAGE_NAME}" "${CHANNEL_NAME}"
    EXPECTED_RESPONSE="get_highest_bundle_version: No valid bundle version found for package: kubevirt-hyperconverged, channel: stable"
    echo "${output}"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}
