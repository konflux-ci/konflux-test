#!/usr/bin/env bats

setup() {
    source test/utils.sh
}

# In unittests_bash/test_cosign.bats
@test "cosign binary is in expected location" {
    run test -f /usr/local/bin/cosign
    [ "$status" -eq 0 ]
}

@test "cosign version command succeeds" {
    run /usr/local/bin/cosign version
    [ "$status" -eq 0 ]
    # Look for GitVersion or version (case-insensitive)
    [[ "$output" =~ "GitVersion" ]] || [[ "$output" =~ "version" ]] || [[ "$output" =~ "Version" ]]
}


@test "cosign verify command exists" {
    run /usr/local/bin/cosign verify --help
    [ "$status" -eq 0 ]
    # More flexible - just check it mentions verify or signature
    [[ "$output" =~ "verify" ]] || [[ "$output" =~ "signature" ]]
}

@test "cosign generate-key-pair command exists" {
    run /usr/local/bin/cosign generate-key-pair --help
    [ "$status" -eq 0 ]
    # More flexible - just check it mentions key or generate
    [[ "$output" =~ "key" ]] || [[ "$output" =~ "generate" ]]
}

@test "cosign triangulate command works" {
    run /usr/local/bin/cosign triangulate busybox:latest
    [ "$status" -eq 0 ]
}

@test "cosign verify-blob command exists" {
    run cosign verify-blob --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Verify a signature on the supplied blob" ]]
}


@test "cosign handles invalid commands gracefully" {
    run cosign invalid-command
    [ "$status" -ne 0 ]
}

@test "cosign can process image references" {
    run timeout 10s cosign triangulate quay.io/konflux-ci/buildah-task:latest
    [ "$status" -eq 0 ]
}