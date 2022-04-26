#!/usr/bin/env bats

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

# CLAIR for test_clair
@test "/project/clair/vulnerabilities-check" {
  run conftest test --namespace required_checks --policy $POLICY_PATH/clair/vulnerabilities-check.rego clair.json
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
