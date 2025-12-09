#!/usr/bin/env bats

setup() {
    source test/utils.sh
    OPM_RENDER_CACHE=$(mktemp -d)
    REPLACE_MIRROR_TEST_TMP=$(mktemp -d)

    RETRY_COUNT=0
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
        INDEX_JSON='{"manifests":[{"platform":{"architecture":"amd64"}},{"platform":{"architecture":"arm64"}}]}'
        MANIFEST_JSON='{"schemaVersion":2,"mediaType":"application/vnd.oci.image.manifest.v1+json","config":{"mediaType":"application/vnd.oci.image.config.v1+json","digest":"valid-manifest-amd64","size":14208},"annotations":{"org.opencontainers.image.base.name":"registry.redhat.io/openshift4/ose-operator-registry:v4.12"}}'
        LABELS_JSON='{"Name":"valid-manifest-amd64","Architecture":"amd64","Labels":{"architecture":"arm64","name":"my-image"},"Digest":"valid-manifest-amd64","Os":"linux"}'

        # The --raw inspects return the OCI metadata for the image references. This includes the mediaType, manifests (for image indexes),
        # digests and their platforms, and annotations.
        # The non-raw skopeo inspect returns information about the image. This is primarily used to get the digest and architecture of an image from its OCI Image Manifest.

        # registry/image@valid-url
        if [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image@valid-url" ]]; then
            echo '{"schemaVersion":2,"mediaType":"application/vnd.oci.image.index.v1+json","manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"valid-manifest-amd64","size":928,"platform":{"architecture":"amd64","os":"linux"}},{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"valid-manifest-arm64","size":928,"platform":{"architecture":"arm64","os":"linux"}}]}'

        # registry/image@invalid
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@invalid" ]]; then
             echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@invalid" ]]; then
            echo $MANIFEST_JSON

        # registry/image@valid-manifest-amd64
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/image@valid-manifest-amd64" || $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@valid-manifest-amd64" ]]; then
            echo '{"Name": "valid-manifest-amd64", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-manifest-amd64", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image@valid-manifest-amd64" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@valid-manifest-amd64" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-manifest-amd64","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.12"}}'
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/image@valid-manifest-amd64" || $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@invalid" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-manifest-amd64","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.12"}}'
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3 == "--no-tags" && $4 == "docker://registry/fbc-fragment@valid-manifest-amd64" ]]; then
            echo $LABELS_JSON
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@valid-manifest-amd64" ]]; then
            echo $INDEX_JSON

        #registry/image@valid-url-arm64
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/image@valid-url-arm64" ]]; then
            echo '{"Name": "valid-manifest-arm64", "Architecture": "arm64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-manifest-arm64", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image@valid-manifest-arm64" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-manifest-arm64","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.12"}}'

        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/image-manifest@valid-labels" ]]; then
            # Return a manifest list so 'first_arch' gets populated (e.g., to 'amd64')
            echo '{"manifests":[{"platform":{"architecture":"amd64"}},{"platform":{"architecture":"arm64"}}]}'
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3 == "--no-tags" && $4 == "docker://registry/image-manifest@valid-labels" ]]; then
            echo '{"Name": "valid-labels", "Architecture": "amd64", "Labels": {"architecture":"amd64", "name": "my-image"}, "Digest": "valid-labels", "Os": "linux"}'

        # registry/image-manifest@valid
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image-manifest@valid" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image-manifest@invalid" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-manifest-amd64","size": 14208}}'

        # registry/image-manifest@valid-oci
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/image-manifest@valid-oci" ]]; then
            echo '{"Name": "valid-oci", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-oci", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image-manifest@valid-oci" || $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/image@valid-url-arm64" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-oci","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry@sha256:12345"}}'
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/image-manifest@valid-oci" ]]; then
            echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3 == "--no-tags" && $4 == "docker://registry/image-manifest@valid-oci" ]]; then
            echo $LABELS_JSON

        # registry/fbc-fragment@valid-success
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "docker://registry/fbc-fragment@valid-success" ]]; then
            echo '{"Name": "valid-success", "Architecture": "amd64", "Labels": {"architecture":"arm64", "name": "my-image"}, "Digest": "valid-success", "Os": "linux"}'
        elif [[ $1 == "inspect" && $2 == "--no-tags" && $3 == "--raw" && $4 == "docker://registry/fbc-fragment@valid-success" ]]; then
            echo '{"schemaVersion": 2,"mediaType": "application/vnd.oci.image.manifest.v1+json","config": {"mediaType": "application/vnd.oci.image.config.v1+json","digest": "valid-success","size": 14208},"annotations": {"org.opencontainers.image.base.name": "registry.redhat.io/openshift4/ose-operator-registry:v4.15", "org.opencontainers.image.base.digest": "boo"}}'
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@valid-success" ]]; then
            echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3 == "--no-tags" && $4 == "docker://registry/fbc-fragment@valid-success" ]]; then
            echo $LABELS_JSON

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
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@isolated" ]]; then
            echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3 == "--no-tags" && $4 == "docker://registry/fbc-fragment@isolated" ]]; then
            echo $LABELS_JSON

        # registry/fbc-fragment@label-array-valid
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@label-array-valid" ]]; then
            echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3=="--no-tags" && $4 == "docker://registry/fbc-fragment@label-array-valid" ]]; then
            echo '{"Labels": {"com.redhat.fbc.openshift.version": ["v4.19","v4.20","v4.21"]}}'

        # registry/fbc-fragment@label-not-array
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@label-not-array" ]]; then
            echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3=="--no-tags" && $4 == "docker://registry/fbc-fragment@label-not-array" ]]; then
            echo '{"Labels": {"com.redhat.fbc.openshift.version":"v4.19"}}'


        # registry/fbc-fragment@label-empty-array
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@label-empty-array" ]]; then
            echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3=="--no-tags" && $4 == "docker://registry/fbc-fragment@label-empty-array" ]]; then
            echo '{"Labels": {"com.redhat.fbc.openshift.version":[]}}'

        # label-array-invalid-item
        elif [[ $1 == "inspect" && $2 == "--raw" && $3 == "docker://registry/fbc-fragment@label-array-invalid-item" ]]; then
            echo $INDEX_JSON
        elif [[ $1 == "inspect" && $2 == --override-arch=* && $3=="--no-tags" && $4 == "docker://registry/fbc-fragment@label-array-invalid-item" ]]; then
            echo '{"Labels": {"com.redhat.fbc.openshift.version":["v4.19", "4.19", "vv5.0"]}}'



        elif [[ $1 == "copy" && $2 == docker://registry.fedoraproject.org/fedora-minimal@sha256:e565f9eaa4dd2026c2e94d972fae8e4008f5df182519158e739ccf0214b19e7f ]]; then            
            # Extract the oci output dir: oci:./image-under-test-UUID
            output_dir="${3#oci:}"
            
            mkdir -p "${output_dir}/blobs/sha256"

            # index.json
            cat > "${output_dir}/index.json" <<EOF
{"schemaVersion":2,"manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:dfda741a47851931ae3cade52f8cb5ecb77c00f5b5c95c02d59184d8364a4ef2","size":406}]}
EOF

            # manifest blob
            cat > "${output_dir}/blobs/sha256/dfda741a47851931ae3cade52f8cb5ecb77c00f5b5c95c02d59184d8364a4ef2" <<EOF
{"schemaVersion":2,"mediaType":"application/vnd.oci.image.manifest.v1+json","config":{"mediaType":"application/vnd.oci.image.config.v1+json","digest":"sha256:ae9d4215ca7ef264f30c90c30f8f2edecec11d8185ab054cbb0d00c96db57167","size":440},"layers":[{"mediaType":"application/vnd.oci.image.layer.v1.tar+gzip","digest":"sha256:43b36f43b4e054a7838cf4288fc9aa8abcbb8c70ba11deccfa47ae32ef098603","size":54752205}]}
EOF

            # config blob
            cat > "${output_dir}/blobs/sha256/ae9d4215ca7ef264f30c90c30f8f2edecec11d8185ab054cbb0d00c96db57167" <<EOF
{"created":"2020-10-08T06:49:10Z","architecture":"amd64","os":"linux","config":{"Env":["DISTTAG=f32container","FGC=f32","container=oci"],"Cmd":["/bin/bash"],"Labels":{"license":"MIT","name":"fedora","vendor":"Fedora Project","version":"32"}},"rootfs":{"type":"layers","diff_ids":["sha256:5eb2a76183d65aea617844663a13a9edee328b1d32e1818a206273bb37c68534"]},"history":[{"created":"2020-10-08T06:49:10Z","comment":"Created by Image Factory"}]}
EOF

            return 0

        elif [[ $1 == "copy" && $2 == docker://registry.fedoraproject.org/fedora-minimal@sha256:46d9dd1088e30a5ae8cf0f3907ce97c11f59d189fc2067d96264568945a2923e ]]; then            
            # Extract the oci output dir: oci:./image-under-test-UUID
            output_dir="${3#oci:}"
            
            mkdir -p "${output_dir}/blobs/sha256"

            # index.json
            cat > "${output_dir}/index.json" <<EOF
{"schemaVersion":2,"manifests":[{"mediaType":"application/vnd.oci.image.manifest.v1+json","digest":"sha256:2eb7c02f794d119db9e46482be96fbffa3f2ca8d1902418375ef49bb459e4486","size":406}]}
EOF

            return 0

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
        elif [[ $1 == "render" && $2 == "registry.redhat.io/redhat/redhat-operator-index:v4.15@randomsha256" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[], "relatedImages": [{"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@not-my-other-sha", "properties":[], "relatedImages": [{"name": "foo-baz", "image": "registry.redhat.io/foo/bar@sha256:my-bar-sha"}]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.io/random-index:v4.15" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[], "relatedImages": [{"name": "foo-bar", "image": "registry.redhat.io/foo/bar@sha256:my-bar-sha"}, {"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha", "properties":[]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.io/random-index:v4.20" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@random-image", "properties":[]}{"schema": "olm.package", "name": "not-rhbk-operator"}{"schema": "olm.bundle", "package": "not-rhbk-operator", "image": "registry.redhat.io/not-rhbk/operator-bundle@my-other-sha", "properties":[]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.io/random-index-2:v4.20" ]]; then
            echo '{"schema": "olm.package", "name": "rhbk-operator"}{"schema": "olm.bundle", "package": "rhbk-operator", "image": "registry.redhat.io/rhbk/keycloak-operator-bundle@my-sha", "properties":[], "relatedImages": [{"name": "foo-bar", "image": "registry.redhat.io/foo/bar@sha256:my-bar-sha"}, {"name": "foo-baz", "image": "registry.redhat.io/foo/baz@sha256:my-sha"}]}'
            return 0
        elif [[ $1 == "render" && $2 == "registry.redhat.io/redhat/redhat-operator-index:v4.12" ]]; then
            echo 'Invalid index'
            return 1
        else
            echo 'Invalid value'
            return 1
        fi
    }

    get_retry_expected_output() {
        local -r interval=${RETRY_INTERVAL:-5}
        local -r max_retries=${RETRY_COUNT:-3}
        expected_string=""

        if [[ max_retries -gt 0 ]];then
        for (( i=1; i<=${max_retries}; i++ ));do
            expected_string+="info: Retrying again in ${interval} seconds...\n"
        done
        fi
        echo -n "${expected_string}"
    }

    # Create a fake catalog.json file for replace_mirror_pullspec_with_source test
    cat > "${REPLACE_MIRROR_TEST_TMP}/catalog.json" <<EOF
{
    "schema": "olm.bundle",
    "name": "gatekeeper-operator.v3.11.1",
    "image": "example.com/gatekeeper/gatekeeper-operator-bundle:v3.11.1",
    "relatedImages": [
        {
            "name": "gatekeeper",
            "image": "example.com/openpolicyagent/gatekeeper:v3.11.1"
        },
        {
            "name": "operator",
            "image": "example.com/gatekeeper/gatekeeper-operator:v3.11.1"
        },
        {
            "name": "operator-sha",
            "image": "example.com/gatekeeper/gatekeeper-operator:@sha256:60635156d6b4e54529195af3bdd07329dcbe6239757db86e536dbe561aa77247"
        }
    ]
}
EOF

    # Create a fake IDMS file for replace_mirror_pullspec_with_source test
    cat > "${REPLACE_MIRROR_TEST_TMP}/idms.yaml" <<EOF
---
apiVersion: operator.openshift.io/v1alpha1
kind: ImageDigestMirrorSet
spec:
  imageDigestMirrors:
  - mirrors:
    - example.com/gatekeeper/gatekeeper-operator-bundle
    source: quay.io/gatekeeper/gatekeeper-operator-bundle
  - mirrors:
    - example.com/openpolicyagent/gatekeeper
    source: quay.io/openpolicyagent/gatekeeper
  - mirrors:
    - example.com/gatekeeper/gatekeeper-operator
    source: quay.io/gatekeeper/gatekeeper-operator
EOF
}

teardown() {
    rm -rf $OPM_RENDER_CACHE $REPLACE_MIRROR_TEST_TMP
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

@test "Get base image: registry/image@valid-url-arm64" {
    run get_base_image registry/image@valid-url-arm64
    EXPECTED_RESPONSE='registry.redhat.io/openshift4/ose-operator-registry:v4.12'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get base image: registry/fbc-fragment@valid-success" {
    run get_base_image registry/fbc-fragment@valid-success
    EXPECTED_RESPONSE='registry.redhat.io/openshift4/ose-operator-registry:v4.15@boo'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Validate_ocp_version: valid versions" {
    for v in v4.19 4.20 v4.0; do
        run validate_ocp_version "$v"
        [[ "$status" -eq 0 ]]
    done
}

@test "Validate_ocp_version: invalid formats" {
    for v in v4.19.1 v5.1 v4.x banana; do
        run validate_ocp_version "$v"
        EXPECTED_RESPONSE="Invalid OCP version $v (expected format v4.x or 4.x)."
        [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
    done
}

@test "Validate_ocp_version: missing parameter" {
    run validate_ocp_version ""
    EXPECTED_RESPONSE="Missing OCP_VERSION PARAMETER"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get OPM version from OCP version - missing parameter" {
    run ocp_to_opm_version_mapping
    EXPECTED_RESPONSE='Missing OCP_VERSION PARAMETER'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get OPM version from OCP version - default value" {
    run ocp_to_opm_version_mapping v4.9
    EXPECTED_RESPONSE="opm-v1.50.0"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get OPM version from OCP version 4.x" {
    run ocp_to_opm_version_mapping 4.17
    EXPECTED_RESPONSE="opm-v1.40.0"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get OPM version from OCP version v4.x" {
    run ocp_to_opm_version_mapping v4.17
    EXPECTED_RESPONSE="opm-v1.40.0"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get OPM version from OCP version - invalid ocp version v5.1" {
    run ocp_to_opm_version_mapping v5.1
    EXPECTED_RESPONSE="Invalid OCP version v5.1 (expected format v4.x or 4.x)."
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get OPM version from OCP version - invalid ocp version v4.1.1" {
    run ocp_to_opm_version_mapping v4.1.1
    EXPECTED_RESPONSE="Invalid OCP version v4.1.1 (expected format v4.x or 4.x)."
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get OCP version from fragment: registry/image-manifest@valid-oci" {
    run get_ocp_version_from_fbc_fragment registry/image-manifest@valid-oci
    EXPECTED_RESPONSE='get_ocp_version_from_fbc_fragment: No ocp version found; base image tag is empty.'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get OCP version from fragment: registry/fbc-fragment@valid-success" {
    run get_ocp_version_from_fbc_fragment registry/fbc-fragment@valid-success
    EXPECTED_RESPONSE='v4.15'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get OCP version from fragment: registry/fbc-fragment@label-array-valid (label present -> returns JSON array)" {
    # What it tests: reads com.redhat.fbc.openshift.version and returns the JSON array as output.
    run get_ocp_version_from_fbc_fragment registry/fbc-fragment@label-array-valid
    EXPECTED_RESPONSE='["v4.19","v4.20","v4.21"]'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get OCP version from fragment: registry/fbc-fragment@label-not-array (label present but not array -> error)" {
    # What it tests: label must be a JSON array, not a string/object/etc.
    run get_ocp_version_from_fbc_fragment registry/fbc-fragment@label-not-array
    EXPECTED_RESPONSE="get_ocp_version_from_fbc_fragment: Label \"com.redhat.fbc.openshift.version\" must contain a non-empty JSON array, got: v4.19"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]

}

@test "Get OCP version from fragment: registry/fbc-fragment@label-empty-array (label present but [] -> error)" {
    # What it tests: rejects empty array.
    run get_ocp_version_from_fbc_fragment registry/fbc-fragment@label-empty-array
    EXPECTED_RESPONSE="get_ocp_version_from_fbc_fragment: Label \"com.redhat.fbc.openshift.version\" must contain a non-empty JSON array, got: []"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get OCP version from fragment: registry/fbc-fragment@label-array-invalid-item (label present, array item invalid -> error)" {
  # What it tests: validate_ocp_version is called for each element and failure bubbles up.
  run get_ocp_version_from_fbc_fragment registry/fbc-fragment@label-array-invalid-item
  EXPECTED_RESPONSE="Invalid OCP version vv5.0 (expected format v4.x or 4.x)."
  [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
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
    run get_unreleased_fbc_related_images -i registry/fbc-fragment:tag@isolated -b registry.io/random-index-2:v4.20
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
    EXPECTED_RESPONSE=$(cat <<EOF
get_image_labels: First architecture found: amd64
architecture=amd64
name=my-image
EOF
)
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get Image Labels: missing image" {
    run get_image_labels
    EXPECTED_RESPONSE="get_image_labels: missing positional parameter \$1 (image pull spec)"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get Image Labels: registry/image-manifest:tag@invalid" {
    run get_image_labels registry/image-manifest:tag@invalid

    local EXPECTED_LINE_1="get_image_labels: First architecture found:"
    local EXPECTED_LINE_2="get_image_labels: failed to inspect the image"
    local EXPECTED_ERROR_LINE="Invalid numeric literal at line 1, column 13"

    [[ "$status" -eq 1 \
        && "${output}" == *"${EXPECTED_LINE_1}"* \
        && "${output}" == *"${EXPECTED_LINE_2}"* \
        && "${output}" == *"${EXPECTED_ERROR_LINE}"* ]]
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

@test "Get bundle arches: success" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": [
        {
            "type": "olm.csv.metadata",
            "value": {
                "labels": {
                    "operatorframework.io/arch.amd64": "supported",
                    "operatorframework.io/arch.arm64": "supported",
                    "operatorframework.io/arch.ppc64le": "supported",
                    "operatorframework.io/arch.s390x": "unsupported",
                    "operatorframework.io/os.linux": "supported"
                }
            }
        }
    ]
}
EOF
)
    run get_bundle_arches "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE=$(echo "amd64 arm64 ppc64le"  | tr ' ' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get bundle arches: no arches found" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": [
        {
            "type": "olm.csv.metadata",
            "value": {}
        }
    ]
}
EOF
)
    run get_bundle_arches "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE="amd64"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Group bundle images by package: two packages" {
    BUNDLE_IMAGES=$(echo "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"  | tr ' ' '\n')
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.17.5",
    "package": "kubevirt-hyperconverged-v1",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db",
    "properties": []
}
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.99.0",
    "package": "kubevirt-hyperconverged-v2",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": []
}
EOF
)
    run group_bundle_images_by_package "${RENDER_OUT_FBC}" "${BUNDLE_IMAGES}"
    EXPECTED_RESPONSE='{"kubevirt-hyperconverged-v1":["registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db"],"kubevirt-hyperconverged-v2":["registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"]}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Group bundle images by package: one package" {
    BUNDLE_IMAGES=$(echo "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"  | tr ' ' '\n')
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.17.5",
    "package": "kubevirt-hyperconverged-v1",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db",
    "properties": []
}
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.99.0",
    "package": "kubevirt-hyperconverged-v1",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": []
}
EOF
)
    run group_bundle_images_by_package "${RENDER_OUT_FBC}" "${BUNDLE_IMAGES}"
    EXPECTED_RESPONSE='{"kubevirt-hyperconverged-v1":["registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db","registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"]}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Group bundle images by package: no packages found" {
    BUNDLE_IMAGES=$(echo "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"  | tr ' ' '\n')
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.17.5",
    "package": "kubevirt-hyperconverged-v1",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0feczxcvb",
    "properties": []
}
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.99.0",
    "package": "kubevirt-hyperconverged-v1",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f911asdfg",
    "properties": []
}
EOF
)
    run group_bundle_images_by_package "${RENDER_OUT_FBC}" "${BUNDLE_IMAGES}"
    EXPECTED_RESPONSE="group_bundle_images_by_package: No matching packages found for the provided bundle images."
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get highest version from bundles list: success" {
    PACKAGE_NAME="kubevirt-hyperconverged"
    CHANNEL_NAME="stable"
    BUNDLE_IMAGES=$(echo "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"  | tr ' ' '\n')
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged",
    "defaultChannel": "stable"
}
{
    "schema": "olm.channel",
    "name": "stable",
    "package": "kubevirt-hyperconverged",
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
    "name": "kubevirt-hyperconverged-operator.v4.17.3",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db",
    "properties": []
}
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.17.4",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": []
}
EOF
)
    run get_highest_version_from_bundles_list "${RENDER_OUT_FBC}" "${PACKAGE_NAME}" "${CHANNEL_NAME}" "${BUNDLE_IMAGES}"
    EXPECTED_RESPONSE="registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get highest version from bundles list: no matching bundle versions found" {
    PACKAGE_NAME="kubevirt-hyperconverged"
    CHANNEL_NAME="stable"
    BUNDLE_IMAGES=$(echo "registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec637db registry.redhat.io/container-native-virtualization/hco-bundle-registry@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"  | tr ' ' '\n')
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.package",
    "name": "kubevirt-hyperconverged",
    "defaultChannel": "stable"
}
{
    "schema": "olm.channel",
    "name": "stable",
    "package": "kubevirt-hyperconverged",
    "entries": [
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.0"
        },
        {
            "name": "kubevirt-hyperconverged-operator.v4.17.1"
        }
    ]
}
EOF
)
    run get_highest_version_from_bundles_list "${RENDER_OUT_FBC}" "${PACKAGE_NAME}" "${CHANNEL_NAME}" "${BUNDLE_IMAGES}"
    EXPECTED_RESPONSE="get_highest_version_from_bundles_list: No matching bundle versions found in the provided image list."
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get highest version from bundles list: success bundle vX.Y.Z-suffixes" {
    PACKAGE_NAME="kubevirt-hyperconverged"
    CHANNEL_NAME="dev-preview"
    BUNDLE_IMAGES=$(echo "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:4f100135ccbfc726f4b1887703ef7a08453b48c202ba04c0fb7382f0fec11122 registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:ee84abe0ae4bb7a905fbfa99fe193428cf3842a895f081696f6cde04230d3255"  | tr ' ' '\n')
    RENDER_OUT_FBC=$(cat <<EOF
{
    "schema": "olm.channel",
    "name": "dev-preview",
    "package": "kubevirt-hyperconverged",
    "entries": [
        {
            "name": "kubevirt-hyperconverged-operator.v4.99.0-0.1738868945"
        }
    ]
}
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.99.0-0.1738868945",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:ee84abe0ae4bb7a905fbfa99fe193428cf3842a895f081696f6cde04230d3255",
    "properties": []
}
EOF
)
    run get_highest_version_from_bundles_list "${RENDER_OUT_FBC}" "${PACKAGE_NAME}" "${CHANNEL_NAME}" "${BUNDLE_IMAGES}"
    EXPECTED_RESPONSE="registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:ee84abe0ae4bb7a905fbfa99fe193428cf3842a895f081696f6cde04230d3255"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get bundle suggested namespace: success" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": [
        {
            "type": "olm.csv.metadata",
            "value": {
                "annotations": {
                    "operatorframework.io/suggested-namespace": "openshift-cnv"
                }
            }
        }
    ]
}
EOF
)
    run get_bundle_suggested_namespace "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE="openshift-cnv"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get bundle suggested namespace: suggested namespace is not defined" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": [
        {
            "type": "olm.csv.metadata",
            "value": {}
        }
    ]
}
EOF
)
    run get_bundle_suggested_namespace "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE=null
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get bundle suggested namespace: no olm.csv.metadata found" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": []
}
EOF
)
    run get_bundle_suggested_namespace "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE="get_bundle_suggested_namespace: No 'olm.csv.metadata' entry found in bundle properties"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get bundle install modes: success" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": [
        {
            "type": "olm.csv.metadata",
            "value": {
                "installModes": [
                    {
                        "type": "OwnNamespace",
                        "supported": true
                    },
                    {
                        "type": "SingleNamespace",
                        "supported": true
                    },
                    {
                        "type": "MultiNamespace",
                        "supported": false
                    },
                    {
                        "type": "AllNamespaces",
                        "supported": false
                    }
                ]
            }
        }
    ]
}
EOF
)
    run get_bundle_install_modes "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE=$(echo "OwnNamespace SingleNamespace"  | tr ' ' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get bundle install modes: no install modes found" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": [
        {
            "type": "olm.csv.metadata",
            "value": {}
        }
    ]
}
EOF
)
    run get_bundle_install_modes "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE="get_bundle_install_modes: No supported install modes found in bundle"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get bundle install modes: no olm.csv.metadata found" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89",
    "properties": []
}
EOF
)
    run get_bundle_install_modes "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE="get_bundle_install_modes: No 'olm.csv.metadata' entry found in bundle properties"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]
}

@test "Get bundle name: success" {
    RENDER_OUT_BUNDLE=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "kubevirt-hyperconverged-operator.v4.16.7",
    "package": "kubevirt-hyperconverged",
    "image": "registry.redhat.io/container-native-virtualization/hco-bundle-registry-rhel9@sha256:5a75810bdebb97c63cad1d25fe0399ed189b558b50ee6dc1cb61f75f9116aa89"
}
EOF
)
    run get_bundle_name "${RENDER_OUT_BUNDLE}"
    EXPECTED_RESPONSE="kubevirt-hyperconverged-operator.v4.16.7"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Retry Get Image Annotations: registry/image:tag@invalid-url" {
    unset RETRY_COUNT # Use default interval and max_retries
    retry_output=$(get_retry_expected_output)
    run get_image_annotations -i registry/image:tag@invalid-url
    EXPECTED_RESPONSE=$(echo -e -n "${retry_output}"get_image_annotations: failed to inspect the image"")
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]

}

@test "Retry Get Image Labels: registry/image:tag@invalid-url" {
    RETRY_COUNT=1
    RETRY_INTERVAL=1
    retry_output=$(get_retry_expected_output)
    run get_image_labels  registry/image:tag@invalid-url
    EXPECTED_RESPONSE=$(echo -e -n "get_image_labels: First architecture found: \n${retry_output}get_image_labels: failed to inspect the image")

    [[ "${output}" == *"${EXPECTED_RESPONSE}"* && "$status" -eq 1 ]]
}

@test "Retry Get Image Index Manifests: registry/image:tag@invalid-url" {
    RETRY_COUNT=1
    RETRY_INTERVAL=1
    retry_output=$(get_retry_expected_output)
    run get_image_manifests -i registry/image:tag@invalid-url
    EXPECTED_RESPONSE=$(echo -e -n "${retry_output}get_image_manifests: The raw image inspect command failed")
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]

}

@test "Retry OPM Render: registry/image:tag@invalid-url" {
    RETRY_COUNT=1
    RETRY_INTERVAL=1
    retry_output=$(get_retry_expected_output)
    run render_opm -t registry/image:tag@invalid-url
    EXPECTED_RESPONSE=$(echo -e -n "${retry_output}"render_opm: could not render catalog registry/image:tag@invalid-url"")
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 1 ]]

}

@test "Resolve to 0th manifest digest: success" {
    run resolve_to_0th_manifest_digest registry/image@valid-url
    EXPECTED_RESPONSE="registry/image@valid-manifest-amd64"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Serialize image mirrors yaml: success" {
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
    run serialize_image_mirrors_yaml "${yaml_input}"
    EXPECTED_RESPONSE="- mirrors:\n    - quay.io/mirror-namespace/mirror-repo\n    - other-registry.io/namespace/repo\n  source: quay.io/gatekeeper/gatekeeper"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Parse collected image pulls: success" {
    # Create a temporary file
    image_pull_events_file=$(mktemp)

    # Write test content to the temp file
    cat <<EOF > "$image_pull_events_file"
2025-06-10T08:15:52Z,Pulling image "registry-proxy.engineering.redhat.com/rh-osbs/3scale-amp2-apicast-rhel7-operator-metadata@sha256:835301351e6aabdde811a26952e2fae6f32152b59591ca33e62e7cc0dd865984"
2025-06-10T08:15:53Z,Pulling image "quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4fdec809fa6fc74b6b205e2c7f599315b8345e7beedea9ac9aa40eec6090e796"
2025-06-10T08:16:08Z,Pulling image "registry.redhat.io/3scale-amp2/apicast-rhel7-operator@sha256:5888618c5e0f893aabb4a92f34fa8c1146dba2c6ba34470d7dd2e88ef298685c"
2025-06-10T08:14:28Z,Pulling image "brew.registry.redhat.io/rh-osbs/iib:986652"
2025-06-10T08:14:29Z,Pulling image "brew.registry.redhat.io/rh-osbs/iib:986652"
2025-06-10T08:16:45Z,Pulling image "quay.io/operator-framework/scorecard-untar@sha256:2e728c5e67a7f4dec0df157a322dd5671212e8ae60f69137463bd4fdfbff8747"
2025-06-10T08:16:51Z,Pulling image "quay.io/operator-framework/scorecard-test:v1.28.0"
2025-06-10T08:16:52Z,Pulling image "quay.io/operator-framework/scorecard-test:v1.28.0"
EOF

    # Define deployment start time (filtering out events before this)
    DEPLOY_START="2025-06-10T08:15:52Z"

    run parse_collected_image_pulls "$image_pull_events_file" "$DEPLOY_START"

    EXPECTED_RESPONSE=$'quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:4fdec809fa6fc74b6b205e2c7f599315b8345e7beedea9ac9aa40eec6090e796\nquay.io/operator-framework/scorecard-test:v1.28.0\nquay.io/operator-framework/scorecard-untar@sha256:2e728c5e67a7f4dec0df157a322dd5671212e8ae60f69137463bd4fdfbff8747\nregistry-proxy.engineering.redhat.com/rh-osbs/3scale-amp2-apicast-rhel7-operator-metadata@sha256:835301351e6aabdde811a26952e2fae6f32152b59591ca33e62e7cc0dd865984\nregistry.redhat.io/3scale-amp2/apicast-rhel7-operator@sha256:5888618c5e0f893aabb4a92f34fa8c1146dba2c6ba34470d7dd2e88ef298685c'

    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Collect scorecard config images: success" {
    yaml_input=$(cat <<EOF
---
apiVersion: scorecard.operatorframework.io/v1alpha3
kind: Configuration
metadata:
  name: config
stages:
- parallel: true
  tests:
  - entrypoint:
    - scorecard-test
    - basic-check-spec
    image: quay.io/operator-framework/scorecard-test:v1.31.0
    labels:
      suite: basic
      test: basic-check-spec-test
    storage:
      spec:
        mountPath: {}
  - entrypoint:
    - scorecard-test
    - olm-bundle-validation
    image: quay.io/operator-framework/scorecard-test:v1.33.0
    labels:
      suite: olm
      test: olm-bundle-validation-test
    storage:
      spec:
        mountPath: {}
storage:
  spec:
    mountPath: {}
EOF
)

    run collect_scorecard_config_images "$yaml_input"
    EXPECTED_RESPONSE=$'quay.io/operator-framework/scorecard-test:v1.31.0\nquay.io/operator-framework/scorecard-test:v1.33.0'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Collect scorecard config images: no stages key" {
    yaml_input=$(cat <<EOF
---
apiVersion: scorecard.operatorframework.io/v1alpha3
kind: Configuration
metadata:
  name: config
storage:
  spec:
    mountPath: {}
EOF
)

    run collect_scorecard_config_images "$yaml_input"
    EXPECTED_RESPONSE=""
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Collect scorecard config images: no tests key" {
    yaml_input=$(cat <<EOF
---
apiVersion: scorecard.operatorframework.io/v1alpha3
kind: Configuration
metadata:
  name: config
stages:
- parallel: true
storage:
  spec:
    mountPath: {}
EOF
)

    run collect_scorecard_config_images "$yaml_input"
    EXPECTED_RESPONSE=""
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Collect scorecard config images: one image missing" {
    yaml_input=$(cat <<EOF
---
apiVersion: scorecard.operatorframework.io/v1alpha3
kind: Configuration
metadata:
  name: config
stages:
- parallel: true
  tests:
  - entrypoint:
    - scorecard-test
    - basic-check-spec
    image: quay.io/operator-framework/scorecard-test:v1.31.0
    labels:
      suite: basic
      test: basic-check-spec-test
    storage:
      spec:
        mountPath: {}
  - entrypoint:
    - scorecard-test
    - olm-bundle-validation
    labels:
      suite: olm
      test: olm-bundle-validation-test
    storage:
      spec:
        mountPath: {}
storage:
  spec:
    mountPath: {}
EOF
)

    run collect_scorecard_config_images "$yaml_input"
    EXPECTED_RESPONSE="quay.io/operator-framework/scorecard-test:v1.31.0"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Handle pyxis response pages: multiple pages" {
    local url="https://catalog.redhat.com/api/containers/graphql/"
    local query="ImagePublishedAndCertifiedStatus"
    local vars='{ "repo": "rhel7/rsyslog", "registry": "registry.access.redhat.com" }'

    page0_response='{
        "data": {
        "results": {
            "page": 0,
            "page_size": 1,
            "total": 2,
            "data": [
            {
                "repositories": [
                { "repository": "rhel7/rsyslog", "registry": "registry.access.redhat.com", "published": true }
                ],
                "parsed_data": {
                "uncompressed_layer_sizes": [
                    { "layer_id": "sha256:5d23c8bb24b5ef6c19d0995cbe4003091bc237ab6941657b74ec7c39116c1c67" }
                ]
                },
                "docker_image_digest": "temp:sha256:c310d8e4591d5dcd6f699bcc42defebf6e1a2b9ae316469ccd14549dc5065042",
                "certified": true
            }
            ]
        }
        }
    }'

    page1_response='{
        "data": {
        "results": {
            "page": 1,
            "page_size": 1,
            "total": 2,
            "data": [
            {
                "repositories": [
                { "repository": "rhel7/rsyslog", "registry": "registry.access.redhat.com", "published": false }
                ],
                "parsed_data": {
                "uncompressed_layer_sizes": [
                    { "layer_id": "sha256:51b15c9293c9ad55df1dc4890a6d1e9511cc2ae1853211084fa0f95447e4ee5d" }
                ]
                },
                "docker_image_digest": "temp:sha256:640e681a32375e843803d06f34a2a4f74eca49be5a3d220c81f0f778d30876c6",
                "certified": false
            }
            ]
        }
        }
    }'

    curl() {
        local body="${*: -1}"
        local page=$(echo "$body" | grep -o '"page":[ ]*[0-9]\+' | grep -o '[0-9]\+')
        case "$page" in
        0) echo "$page0_response" ;;
        1) echo "$page1_response" ;;
        *) echo '{"data":{"results":{"page":99,"page_size":0,"total":2,"data":[]}}}' ;;
        esac
    }

    run handle_pyxis_response_pages "$url" POST "$query" "$vars"
    EXPECTED_RESPONSE=$'{"repositories":[{"repository":"rhel7/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[{"layer_id":"sha256:5d23c8bb24b5ef6c19d0995cbe4003091bc237ab6941657b74ec7c39116c1c67"}]},"docker_image_digest":"temp:sha256:c310d8e4591d5dcd6f699bcc42defebf6e1a2b9ae316469ccd14549dc5065042","certified":true}\n{"repositories":[{"repository":"rhel7/rsyslog","registry":"registry.access.redhat.com","published":false}],"parsed_data":{"uncompressed_layer_sizes":[{"layer_id":"sha256:51b15c9293c9ad55df1dc4890a6d1e9511cc2ae1853211084fa0f95447e4ee5d"}]},"docker_image_digest":"temp:sha256:640e681a32375e843803d06f34a2a4f74eca49be5a3d220c81f0f778d30876c6","certified":false}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Handle pyxis response pages: single page" {
    local url="https://catalog.redhat.com/api/containers/graphql/"
    local query="ImagePublishedAndCertifiedStatus"
    local vars='{}'

    curl() {
        echo '{
        "data": {
            "results": {
            "page": 0,
            "page_size": 2,
            "total": 2,
            "data": [
                {
                "repositories": [
                    { "repository": "rhel8/rsyslog", "registry": "registry.access.redhat.com", "published": true }
                ],
                "parsed_data": {
                    "uncompressed_layer_sizes": [
                    { "layer_id": "sha256:5d23c8bb24b5ef6c19d0995cbe4003091bc237ab6941657b74ec7c39116c1c67" }
                    ]
                },
                "docker_image_digest": "temp:sha256:c310d8e4591d5dcd6f699bcc42defebf6e1a2b9ae316469ccd14549dc5065042",
                "certified": true
                },
                {
                "repositories": [
                    { "repository": "rhel8/rsyslog", "registry": "registry.access.redhat.com", "published": true }
                ],
                "parsed_data": {
                    "uncompressed_layer_sizes": [
                    { "layer_id": "sha256:51b15c9293c9ad55df1dc4890a6d1e9511cc2ae1853211084fa0f95447e4ee5d" }
                    ]
                },
                "docker_image_digest": "temp:sha256:640e681a32375e843803d06f34a2a4f74eca49be5a3d220c81f0f778d30876c6",
                "certified": false
                }
            ]
            }
        }
        }'
    }

    run handle_pyxis_response_pages "$url" POST "$query" "$vars"
    EXPECTED_RESPONSE=$'{"repositories":[{"repository":"rhel8/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[{"layer_id":"sha256:5d23c8bb24b5ef6c19d0995cbe4003091bc237ab6941657b74ec7c39116c1c67"}]},"docker_image_digest":"temp:sha256:c310d8e4591d5dcd6f699bcc42defebf6e1a2b9ae316469ccd14549dc5065042","certified":true}\n{"repositories":[{"repository":"rhel8/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[{"layer_id":"sha256:51b15c9293c9ad55df1dc4890a6d1e9511cc2ae1853211084fa0f95447e4ee5d"}]},"docker_image_digest":"temp:sha256:640e681a32375e843803d06f34a2a4f74eca49be5a3d220c81f0f778d30876c6","certified":false}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Handle pyxis response pages: returns empty when no results found" {
    local url="https://catalog.redhat.com/api/containers/graphql/"
    local query="ImagePublishedAndCertifiedStatus"
    local vars='{}'

    curl() {
        echo '{"data":{"results":{"page":0,"page_size":0,"total":0,"data":[]}}}'
    }

    run handle_pyxis_response_pages "$url" POST "$query" "$vars"
    EXPECTED_RESPONSE=""
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Handle pyxis response pages: returns GraphQL error properly" {
    local url="https://catalog.redhat.com/api/containers/graphql/"
    local query="ImagePublishedAndCertifiedStatus"
    local vars='{}'

    curl() {
        echo '{"errors":[{"message":"Query failed due to something"}]}'
    }

    run handle_pyxis_response_pages "$url" POST "$query" "$vars"
    [[ "$output" == *'"errors":'* ]]
    [ "$status" -eq 1 ]
}

@test "Get image published and certified status: invalid input" {
    run get_image_published_and_certified_status "registry.access.redhat.com" "rhel7/doesnotmatch" "temp:sha256:640e681a32375e843803d06f34a2a4f74eca49be5a3d220c81f0f778d30876c6"
    EXPECTED_RESPONSE="get_image_published_and_certified_status: Invalid input. Usage: get_image_published_and_certified_status <registry> <repo> <digest> <layerDigestList>"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 2 ]]
}

@test "Get image published and certified status: handles no data returned" {
    handle_pyxis_response_pages() {
        # Return nothing to simulate no matches found in Pyxis
        return 0
    }

    run get_image_published_and_certified_status "registry.access.redhat.com" "rhel7/rsyslog" "temp:sha256:640e681a32375e843803d06f34a2a4f74eca49be5a3d220c81f0f778d30876c6" "sha256:14883c6c9fde3cfa1b3708299a4a1171985c67bc582491e97cde04a4aa330ef5" "sha256:51b15c9293c9ad55df1dc4890a6d1e9511cc2ae1853211084fa0f95447e4ee5d"
    EXPECTED_RESPONSE='{"certified":"Not found","published":"Not found"}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image published and certified status: match by docker_image_digest" {
    handle_pyxis_response_pages() {
        echo '{"repositories":[{"repository":"rhel7/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[{"layer_id":"sha256:14883c6c9fde3cfa1b3708299a4a1171985c67bc582491e97cde04a4aa330ef5"},{"layer_id":"sha256:51b15c9293c9ad55df1dc4890a6d1e9511cc2ae1853211084fa0f95447e4ee5d"}]},"docker_image_digest":"temp:sha256:640e681a32375e843803d06f34a2a4f74eca49be5a3d220c81f0f778d30876c6","certified":false}'
        echo '{"repositories":[{"repository":"rhel7/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[]},"docker_image_digest":"temp:sha256:686262b6bae340ef39974128b7c59730a246e09cefb9d2afaf5ebcfccebb624c","certified":false}'
        echo '{"repositories":[{"repository":"rhel7/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[{"layer_id":"sha256:5d23c8bb24b5ef6c19d0995cbe4003091bc237ab6941657b74ec7c39116c1c67"},{"layer_id":"sha256:abab321ee7e04dd9e35a80d2d9114c22b09f9c926246f8bd5303bd4b6d1613b6"}]},"docker_image_digest":"temp:sha256:c310d8e4591d5dcd6f699bcc42defebf6e1a2b9ae316469ccd14549dc5065042","certified":true}'
    }

    layerDigestList=("dummy-layer") # Doesn't matter for this test

    run get_image_published_and_certified_status "registry.access.redhat.com" "rhel7/rsyslog" "temp:sha256:c310d8e4591d5dcd6f699bcc42defebf6e1a2b9ae316469ccd14549dc5065042" "${layerDigestList[@]}"
    EXPECTED_RESPONSE='{"certified":"true","published":"true"}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get image published and certified status: match by layer digests" {
    handle_pyxis_response_pages() {
        echo '{"repositories":[{"repository":"rhel7/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[]},"docker_image_digest":"temp:sha256:686262b6bae340ef39974128b7c59730a246e09cefb9d2afaf5ebcfccebb624c","certified":false}'
        echo '{"repositories":[{"repository":"rhel7/rsyslog","registry":"registry.access.redhat.com","published":true}],"parsed_data":{"uncompressed_layer_sizes":[{"layer_id":"sha256:5d23c8bb24b5ef6c19d0995cbe4003091bc237ab6941657b74ec7c39116c1c67"},{"layer_id":"sha256:abab321ee7e04dd9e35a80d2d9114c22b09f9c926246f8bd5303bd4b6d1613b6"}]},"docker_image_digest":"temp:sha256:c310d8e4591d5dcd6f699bcc42defebf6e1a2b9ae316469ccd14549dc5065042","certified":true}'
    }

    layerDigestList=("sha256:5d23c8bb24b5ef6c19d0995cbe4003091bc237ab6941657b74ec7c39116c1c67" "sha256:abab321ee7e04dd9e35a80d2d9114c22b09f9c926246f8bd5303bd4b6d1613b6")

    run get_image_published_and_certified_status "registry.access.redhat.com" "rhel7/rsyslog" "sha256:doesnotmatch" "${layerDigestList[@]}"
    EXPECTED_RESPONSE='{"certified":"true","published":"true"}'
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get uncompressed layer digests: success" {
    pull_spec="registry.fedoraproject.org/fedora-minimal@sha256:e565f9eaa4dd2026c2e94d972fae8e4008f5df182519158e739ccf0214b19e7f"

    run get_uncompressed_layer_digests "${pull_spec}"
    EXPECTED_RESPONSE="sha256:5eb2a76183d65aea617844663a13a9edee328b1d32e1818a206273bb37c68534"
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "$status" -eq 0 ]]
}

@test "Get uncompressed layer digests: failure" {
    pull_spec="registry.fedoraproject.org/fedora-minimal@sha256:46d9dd1088e30a5ae8cf0f3907ce97c11f59d189fc2067d96264568945a2923e"

    run get_uncompressed_layer_digests "${pull_spec}"
    [[ "$output" == *"get_uncompressed_layer_digests: Image index blob not found"* ]]
    [ "$status" -eq 1 ]
}


@test "replace_mirror_pullspec_with_source: successful replacement" {
    run replace_mirror_pullspec_with_source "${REPLACE_MIRROR_TEST_TMP}/idms.yaml" "${REPLACE_MIRROR_TEST_TMP}/catalog.json"

    # Verify that the function executed successfully
    [ "$status" -eq 0 ]

    # Verify that the output contains the success message
    [[ "$output" == *"Replacement process completed"* ]]

    # Verify that the file content was changed correctly
    expected_content='{
    "schema": "olm.bundle",
    "name": "gatekeeper-operator.v3.11.1",
    "image": "quay.io/gatekeeper/gatekeeper-operator-bundle:v3.11.1",
    "relatedImages": [
        {
            "name": "gatekeeper",
            "image": "quay.io/openpolicyagent/gatekeeper:v3.11.1"
        },
        {
            "name": "operator",
            "image": "quay.io/gatekeeper/gatekeeper-operator:v3.11.1"
        },
        {
            "name": "operator-sha",
            "image": "quay.io/gatekeeper/gatekeeper-operator:@sha256:60635156d6b4e54529195af3bdd07329dcbe6239757db86e536dbe561aa77247"
        }
    ]
}'
    # Compare the file contents after removing whitespace
    diff <(echo "$expected_content" | jq -c .) <(jq -c . "${REPLACE_MIRROR_TEST_TMP}/catalog.json")
}

@test "replace_mirror_pullspec_with_source: idms file not found" {
    run replace_mirror_pullspec_with_source "${REPLACE_MIRROR_TEST_TMP}/nonexistent-idms.yaml" "${REPLACE_MIRROR_TEST_TMP}/catalog.json"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipping replacement"* ]]

    # Verify that the catalog.json file was not changed
    original_content=$(cat <<EOF
{
    "schema": "olm.bundle",
    "name": "gatekeeper-operator.v3.11.1",
    "image": "example.com/gatekeeper/gatekeeper-operator-bundle:v3.11.1",
    "relatedImages": [
        {
            "name": "gatekeeper",
            "image": "example.com/openpolicyagent/gatekeeper:v3.11.1"
        },
        {
            "name": "operator",
            "image": "example.com/gatekeeper/gatekeeper-operator:v3.11.1"
        },
        {
            "name": "operator-sha",
            "image": "example.com/gatekeeper/gatekeeper-operator:@sha256:60635156d6b4e54529195af3bdd07329dcbe6239757db86e536dbe561aa77247"
        }
    ]
}
EOF
)
    diff <(echo "$original_content" | jq -c .) <(jq -c . "${REPLACE_MIRROR_TEST_TMP}/catalog.json")
}

@test "replace_mirror_pullspec_with_source: catalog file not found" {
    run replace_mirror_pullspec_with_source "${REPLACE_MIRROR_TEST_TMP}/idms.yaml" "${REPLACE_MIRROR_TEST_TMP}/nonexistent-catalog.json"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Catalog file not found"* ]]
}

@test "replace_mirror_pullspec_with_source: invalid arguments" {
    run replace_mirror_pullspec_with_source "${REPLACE_MIRROR_TEST_TMP}/idms.yaml"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "replace_mirror_pullspec_with_source: sed command fails" {
    # Mock the sed command to make it fail
    sed() {
        echo "Sed failed" >&2
        return 1
    }
    export -f sed

    run replace_mirror_pullspec_with_source "${REPLACE_MIRROR_TEST_TMP}/idms.yaml" "${REPLACE_MIRROR_TEST_TMP}/catalog.json"
    [ "$status" -eq 1 ]
    [[ "$output" == *"ERROR: Replacement failed"* ]]

    # Unset the mock
    unset -f sed
}

@test "replace_mirror_pullspec_with_source: no matching mirrors to replace" {
    # Create a catalog with no matching mirrors
    cat > "${REPLACE_MIRROR_TEST_TMP}/catalog_no_match.json" <<EOF
{
    "schema": "olm.bundle",
    "name": "some-other-operator",
    "image": "some.registry/some/operator:1.0.0"
}
EOF
    original_content=$(cat "${REPLACE_MIRROR_TEST_TMP}/catalog_no_match.json")

    run replace_mirror_pullspec_with_source "${REPLACE_MIRROR_TEST_TMP}/idms.yaml" "${REPLACE_MIRROR_TEST_TMP}/catalog_no_match.json"
    [ "$status" -eq 0 ]

    # Verify that the file remained unchanged
    diff <(echo "$original_content" | jq -c .) <(jq -c . "${REPLACE_MIRROR_TEST_TMP}/catalog_no_match.json")
}

@test "get_image_mirror_list: match registry" {
    mirror_map=$(cat <<EOF
{
  "registry.redhat.io": [
    "quay.io"
  ],
  "registry.redhat.io/salami/soppressata-toolset": [
    "quay.io/salami/soppressata-toolset"
  ],
  "registry.redhat.io/salami/nduja-rhel9": [
    "quay.io/salami/nduja-rhel9",
    "some.registry/salami/nduja-rhel9"
  ]
}
EOF
)
    reg_and_repo="registry.redhat.io/salami/operator-bundle"
    run get_image_mirror_list "${reg_and_repo}" "${mirror_map}"
    [[ "quay.io/salami/operator-bundle" = "${output}" && "${status}" -eq 0 ]]
}

@test "get_image_mirror_list: match registry and namespace" {
    mirror_map=$(cat <<EOF
{
  "registry.redhat.io/salami/preview": [
    "quay.io/salami/preview"
  ],
  "registry.redhat.io/salami/soppressata-toolset": [
    "quay.io/salami/soppressata-toolset"
  ],
  "registry.redhat.io/salami/nduja-rhel9": [
    "quay.io/salami/nduja-rhel9",
    "some.registry/salami/nduja-rhel9"
  ]
}
EOF
)
    reg_and_repo="registry.redhat.io/salami/preview/operator-bundle"
    run get_image_mirror_list "${reg_and_repo}" "${mirror_map}"
    [[ "quay.io/salami/preview/operator-bundle" = "${output}" && "${status}" -eq 0 ]]
}

@test "get_image_mirror_list: match registry, namespace, and repo" {
    mirror_map=$(cat <<EOF
{
  "registry.redhat.io/salami/nduja-rhel9": [
    "quay.io/salami/nduja-rhel9"
  ],
  "registry.redhat.io/salami/soppressata-toolset": [
    "quay.io/salami/soppressata-toolset"
  ],
  "registry.redhat.io/salami/operator-bundle": [
    "quay.io/salami/operator-bundle",
    "brew.registry.redhat.io/rh-osbs/salami-operator-bundle"
  ]
}
EOF
)
    reg_and_repo="registry.redhat.io/salami/operator-bundle"
    run get_image_mirror_list "${reg_and_repo}" "${mirror_map}"
    EXPECTED_RESPONSE=$(echo 'brew.registry.redhat.io/rh-osbs/salami-operator-bundle*quay.io/salami/operator-bundle'| tr '*' '\n')
    [[ "${EXPECTED_RESPONSE}" = "${output}" && "${status}" -eq 0 ]]
}
