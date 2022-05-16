#!/bin/sh -l

check_return_code () {
   if [ $? -eq 0 ]; then
     echo PASS
   else
     echo FAIL
     exit 1
   fi
}

#Clair DATA
curl -H "Content-type: application/json" -XGET 'https://quay.io/api/v1/repository/redhat-appstudio/sample-image/manifest/sha256:fc78d878b68b74c965bdb857fab8a87ef75bf7e411f561b3e5fee97382c785ab/security?vulnerabilities=true' > clair.json

#RPM MANIFEST
curl -X GET 'https://catalog.redhat.com/api/containers/v1/images/id/624bfc54f5a0de7ee0c8335c/rpm-manifest?include=rpms' > rpm-manifest.json

# Label Data
skopeo inspect --no-tags docker://registry.access.redhat.com/ubi8/ubi > label.json
check_return_code

# Deprecated Image
curl -X 'GET' 'https://catalog.redhat.com/api/containers/v1/repositories/registry/registry.access.redhat.com/repository/rhscl%2Fnodejs-8-rhel7' -H 'accept: application/json' > image.json

echo "Starting Integeration-Tests"
bats $POLICY_PATH/conftest.sh
exec $@
