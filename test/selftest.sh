#!/usr/bin/bash

# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

check_return_code () {
   if [ $? -eq 0 ]; then
     echo PASS
   else
     echo FAIL
     exit 1
   fi
}

# Check yq presence
yq --version
check_return_code

#Clair DATA
curl -s -H "Content-type: application/json" -XGET 'https://quay.io/api/v1/repository/redhat-appstudio/sample-image/manifest/sha256:fc78d878b68b74c965bdb857fab8a87ef75bf7e411f561b3e5fee97382c785ab/security?vulnerabilities=true' > clair.json

#RPM MANIFEST
curl -s -X GET 'https://catalog.redhat.com/api/containers/v1/images/id/624bfc54f5a0de7ee0c8335c/rpm-manifest?include=rpms' > rpm-manifest.json

# Label data from example image with valid labels
skopeo inspect --no-tags docker://quay.io/redhat-appstudio/sample-image:test-labels-pass > label.json
check_return_code

# Deprecated Image
curl -s -X 'GET' 'https://catalog.redhat.com/api/containers/v1/repositories/registry/registry.access.redhat.com/repository/rhscl%2Fnodejs-8-rhel7' -H 'accept: application/json' > image.json

# FBC Image label data from example fbc index image
skopeo inspect --no-tags docker://quay.io/redhat-appstudio/sample-image:test-index-pass > fbc_label.json
check_return_code

# FBC Image label data from example invalid fbc index image
skopeo inspect --no-tags docker://quay.io/redhat-appstudio/sample-image:test-index-fail-2 > fbc_label_fail.json
check_return_code

# Test parse_test_output
echo "Testing shell function parse_test_output"
. /utils.sh
conftest test --namespace optional_checks --policy $POLICY_PATH/image/inherited-labels.rego label.json --output=json > unittest.json
TEST_OUTPUT=
parse_test_output sanity_label_check conftest unittest.json
[ "$(echo $TEST_OUTPUT | jq -r '.result')" == "SUCCESS" ] && echo "test_parse_test_output PASSED" || exit 1

echo "Starting Integeration-Tests"
bats $POLICY_PATH/conftest.sh
check_return_code

echo "Test presence of snyk binary"
snyk version
check_return_code

echo "Test presence of ec-cli binary"
ec version
check_return_code

# Test clamscan output format, we are parsing it so we relay on it (including foramt of virus report)
echo "Test clamscan output format"
echo "this is for a test" >> /tmp/virus-test.txt

# we don't have clamDB in this image, fetching full DB would take ages, let's use fake data
sigtool --sha256 /tmp/virus-test.txt > test.hdb
clamscan -d test.hdb /tmp/virus-test.txt > clamscan-result.txt || true  # return code is 1

EXPECTED_LINES="/tmp/virus-test.txt: virus-test.txt.UNOFFICIAL FOUND
----------- SCAN SUMMARY -----------
Known viruses:
Engine version:
Scanned directories:
Scanned files:
Infected files:
Data scanned:
Data read:
Time:
Start Date:
End Date:"

while IFS= read -r line; do
    if ! grep -- "${line}" clamscan-result.txt; then
        echo "Expected pattern not found: \"${line}\"" >&2
        exit 1
    fi
done <<< "${EXPECTED_LINES}"

# END clamscan test
