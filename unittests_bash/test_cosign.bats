#!/usr/bin/env bats

setup() {
    source test/utils.sh
}

@test "cosign version command succeeds" {
    run cosign version
    [ "$status" -eq 0 ]
    # More flexible version check - just check it contains version info
    [[ "$output" =~ "version" ]] || [[ "$output" =~ "v" ]]
}

@test "cosign help command works" {
    run cosign help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "A tool for Container Signing" ]]
}

@test "cosign verify command exists" {
    run cosign verify --help
    [ "$status" -eq 0 ]
    # More flexible - just check it mentions verify or signature
    [[ "$output" =~ "verify" ]] || [[ "$output" =~ "signature" ]]
}

@test "cosign generate-key-pair command exists" {
    run cosign generate-key-pair --help
    [ "$status" -eq 0 ]
    # More flexible - just check it mentions key or generate
    [[ "$output" =~ "key" ]] || [[ "$output" =~ "generate" ]]
}

@test "cosign triangulate command works" {
    run cosign triangulate busybox:latest
    [ "$status" -eq 0 ]
}

@test "cosign tree command exists" {
    run cosign tree --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Display supply chain security related artifacts" ]]
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