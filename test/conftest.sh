#!/usr/bin/env bats

# SPDX-License-Identifier: Apache-2.0

# IMAGES for test_images - positive cases
@test "/project/image/deprecated-labels" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/image/deprecated-labels.rego label.json
  [ "$status" -eq 0 ]
}

@test "/project/image/required-labels" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/image/required-labels.rego label.json
  [ "$status" -eq 0 ]
}

@test "/project/image/optional-labels" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/image/optional-labels.rego label.json
  [ "$status" -eq 0 ]
}

@test "/project/image/inherited-labels_pass" {
  run conftest test --namespace optional_checks --policy $POLICY_PATH/image/inherited-labels.rego label.json
  [ "$status" -eq 0 ]
}

# Testing the inherited labels with the same image provided as the base - expected to fail
@test "/project/image/inherited-labels_fail" {
  run conftest test --namespace optional_checks --policy $POLICY_PATH/image/inherited-labels.rego -d label.json label.json
  [ "$status" -eq 1 ]
}

# CLAIR for test_clair
@test "/project/clair/vulnerabilities-check" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/clair/vulnerabilities-check.rego clair.json
  [ "$status" -eq 0 ]
}


# CLAMAV for test_clamav
@test "/project/clamav/virus-check" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/clamav/virus-check.rego clamav.yaml
  [ "$status" -eq 1 ]
}

# REPOSITORY for test_repo
# Test is expected to fail for deprecated Image.
# Currently test passes even the json is not present. handle it better with output checks in later stage.
@test "/project/repository/deprecated-image" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/repository/deprecated-image.rego image.json
  [ "$status" -eq 1 ]
}

# RPM_MANIFEST for unsigned_rpms
@test "/project/rpm_manifest/unsigned-rpms" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/rpm_manifest/unsigned-rpms.rego rpm-manifest.json
  [ "$status" -eq 0 ]
}

# Test label operators.operatorframework.io.index.configs.v1 for fbc image
@test "/project/image/fbc-labels" {
  run conftest test --namespace fbc_checks --policy $POLICY_PATH/image/required-labels.rego fbc_label.json
  [ "$status" -eq 0 ]
}

# Test label operators.operatorframework.io.index.configs.v1 for invalid fbc image
@test "/project/image/fbc-labels-fail" {
  run conftest test --namespace fbc_checks --policy $POLICY_PATH/image/fbc-labels.rego fbc_label_fail.json
  [ "$status" -eq 1 ]
}


# Test cosign functionality in deprecated-image-check context
@test "cosign_deprecated_image_check_simulation" {
    # Simulate the deprecated-image-check task workflow
    local test_image="quay.io/redhat-appstudio/sample-image:test-labels-pass"
    local arch_imageanddigest="${test_image}@sha256:fc78d878b68b74c965bdb857fab8a87ef75bf7e411f561b3e5fee97382c785ab"
    
    # Test cosign download sbom (this should handle auth gracefully)
    run cosign download sbom "$arch_imageanddigest"
    # Should not fail with authorization error
    if [ "$status" -ne 0 ]; then
        [[ ! "$output" =~ "UNAUTHORIZED" ]]
    fi
}
