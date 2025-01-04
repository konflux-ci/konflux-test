#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0


# returns TEST_OUTPUT json with predefined default. Function accepts optional args to modify result
# see make_result_json_usage for usage
make_result_json() {
  local RESULT=""
  local SUCCESSES=0
  local FAILURES=0
  local WARNINGS=0
  local NOTE="For details, check Tekton task log."
  local NAMESPACE="default"
  local OUTPUT

  make_result_json_usage()
  {
    echo "
  make_result_json  -r RESULT
                    [ -s SUCCESSES ]
                    [ -f FAILURES ]
                    [ -w WARNINGS ]
                    [ -t NOTE ]
                    [ -n NAMESPACE ]
  " >&2
    exit 2
  }

  local OPTIND opt
  while getopts ":r:s:f:w:t:n:" opt; do
      case "${opt}" in
          r)
              RESULT="${OPTARG}" ;;
          s)
              SUCCESSES="${OPTARG}" ;;
          f)
              FAILURES="${OPTARG}" ;;
          w)
              WARNINGS="${OPTARG}" ;;
          t)
              NOTE="${OPTARG}" ;;
          n)
              NAMESPACE="${OPTARG}" ;;
          *)
              make_result_json_usage
              ;;
      esac
  done
  shift $((OPTIND-1))

  if [ -z "${RESULT}" ]; then
    echo "Missing parameter: -r RESULT" >&2
    exit 2
  fi

  case "${RESULT}" in
    SUCCESS|FAILURE|ERROR|WARNING|SKIPPED) ;;  # ok
    *)
        echo "Invalid value for RESULT: ${RESULT}" >&2
        exit 2
        ;;
  esac

  # Generate mandatory fields
  OUTPUT=$(jq -rce \
    --arg date "$(date -u --iso-8601=seconds)" \
    --arg result "${RESULT}" \
    --arg note "${NOTE}" \
    --arg namespace "${NAMESPACE}" \
    --arg successes "${SUCCESSES}" \
    --arg failures "${FAILURES}" \
    --arg warnings "${WARNINGS}" \
    --null-input \
    '{  result: $result,
        timestamp: $date,
        note: $note,
        namespace: $namespace,
        successes: $successes|tonumber,
        failures: $failures|tonumber,
        warnings: $warnings|tonumber
    }')

  echo "${OUTPUT}"
}


# Parse test result and genarate TEST_OUTPUT
parse_test_output() {
  # The name of test
  TEST_NAME=$1
  # The format of json file, can be conftest or sarif
  TEST_RESULT_FORMAT=$2
  # The json file to parse
  TEST_RESULT_FILE=$3

  if [ -z "$TEST_NAME" ]; then
    echo "Missing parameter TEST_NAME" >&2
    exit 2
  fi
  if [ -z "$TEST_RESULT_FORMAT" ]; then
    echo "Missing parameter TEST_RESULT_FORMAT" >&2
    exit 2
  fi
  if [ -z "$TEST_RESULT_FILE" ]; then
    echo "Missing parameter TEST_RESULT_FILE" >&2
    exit 2
  fi

  if [ ! -f "$TEST_RESULT_FILE" ]; then
    echo "File ${TEST_RESULT_FILE} doesn't exist" >&2
    exit 2
  fi

  # Handle the test result with format of sarif
  if [ "$TEST_RESULT_FORMAT" = "sarif" ]; then
    TEST_OUTPUT=$(make_result_json \
      -r "$(jq -rce '(if (.runs[].results | length > 0) then "FAILURE" else "SUCCESS" end)' "${TEST_RESULT_FILE}" || echo 'ERROR')" \
      -f "$(jq -rce '(.runs[].results | length)' "${TEST_RESULT_FILE}")" \
    )

    # Log out the failing runs
    if [ "$(echo "$TEST_OUTPUT" | jq '.failures')" -gt 0 ]
    then
      echo "Task $TEST_NAME failed because of the following issues:"
      jq '.runs[].results // []|map(.message.text) | unique' "$TEST_RESULT_FILE"
    fi
  # Handle the test result with format of conftest
  elif [ "$TEST_RESULT_FORMAT" = "conftest" ]; then

    # current workflow assumes only one result per test, fail early if this is not fullfilled
    local RES_LEN
    RES_LEN=$(jq '. | length' "${TEST_RESULT_FILE}")
    if [ "${RES_LEN}" -ne 1 ]; then
      echo "Cannot create test output, unexpected number of results in file: ${RES_LEN}" >&2
      exit 1
    fi

    TEST_OUTPUT=$(make_result_json \
      -r "$(jq -rce '.[] | (if (.failures | length > 0) then "FAILURE" else "SUCCESS" end)' "${TEST_RESULT_FILE}" || echo 'ERROR')" \
      -n "$(jq -rce '.[] | .namespace' "${TEST_RESULT_FILE}")" \
      -s "$(jq -rce '.[] | .successes' "${TEST_RESULT_FILE}")" \
      -f "$(jq -rce '.[] | (.failures | length)' "${TEST_RESULT_FILE}")" \
    )

    # Log out the failing runs
    if [ "$(echo "$TEST_OUTPUT" | jq '.failures')" -gt 0 ]
    then
      echo "Task $TEST_NAME failed because of the following issues:"
      jq '.[].failures // []|map(.metadata.details.name) | unique' "$TEST_RESULT_FILE"
    fi    
  else
    echo "Unsupported TEST_RESULT_FORMAT $TEST_RESULT_FORMAT"
    exit 1
  fi
}

# The function will be used by the tekton tasks of build-definitions
# It need tekton result path as parameter when generating TEST_OUTPUT task result is needed
handle_error()
{
  exit_code=$?
  if [ "${exit_code}" -ne 0 ]; then
    if [ $# == 0 ]; then
      echo "Unexpected error: Script errored at command: ${BASH_COMMAND}."
      exit 0
    fi

    # The tekton task result path
    TEST_OUTPUT_PATH=$1
    note="Unexpected error: Script errored at command: ${BASH_COMMAND}."
    ERROR_OUTPUT=$(make_result_json -r ERROR -t "$note")
    echo "${ERROR_OUTPUT}" | tee "$TEST_OUTPUT_PATH"
    exit 0
  else
    exit 0
  fi
}


# The function will be used by the tekton tasks of build-definitions
# It returns a map of {arch:digest} for the given image_url
get_image_manifests() {
  local image_url=""

  #Usage information
  get_image_manifests_usage()
  {
    echo "
  get_image_manifests  -i IMAGE_URL
  " >&2
    exit 2
  }

  local OPTIND opt
  while getopts "i:" opt; do
      case "${opt}" in
          i)
              image_url="${OPTARG}" ;;
          *)
              get_image_manifests_usage ;;
      esac
  done
  shift $((OPTIND-1))

  if [ -z "${image_url}" ]; then
    echo "Missing parameter: -i IMAGE_URL" >&2
    exit 2
  fi

  if ! raw_inspect_output=$(skopeo inspect --no-tags --raw docker://"${image_url}"); then
    echo "The raw image inspect command failed" >&2
    exit 1
  fi

  image_manifests=''
  if [ "$(echo "${raw_inspect_output}" | jq 'has("manifests")')" = "true" ]; then
    image_manifests=$(echo "${raw_inspect_output}" | jq -rce ' .manifests | map ( {(.platform.architecture|tostring|ascii_downcase):  .digest} ) | add' )
  else
    if ! image_manifest_command_output=$(skopeo inspect --no-tags docker://"${image_url}"); then
      echo "The image manifest could not be inspected" >&2
      exit 1
    fi
    image_manifests=$(echo "${image_manifest_command_output}" | jq -rce '{(.Architecture) : .Digest}')
  fi

  echo "${image_manifests}"

}

# This function will be used by tekton tasks in build-definitions
# It returns the ocp_version targeted by the FBC fragment
get_ocp_version_from_fbc_fragment() {
  local FBC_FRAGMENT="$1"

  if [ -z "$FBC_FRAGMENT" ]; then
    echo "Missing FBC_FRAGMENT parameter" >&2
    exit 2
  fi

  #Get target ocp version from the fragment
  local ocp_version
  if ! ocp_version=$(skopeo inspect --no-tags --raw docker://"$FBC_FRAGMENT"); then
    echo "Could not inspect image $FBC_FRAGMENT"
    exit 1
  fi

  ocp_version=$(echo "$ocp_version" |  jq -r '.annotations."org.opencontainers.image.base.name"' | sed -e "s/@.*$//" -e "s/^.*://")
  echo "$ocp_version"
}

# Given output of `opm render` command and package name, this function returns
# all unique bundles for the given package in the catalog
extract_unique_bundles_from_catalog() {
  local RENDER_OUT="$1"
  local PACKAGE_NAME="$2"

  if [ -z "$RENDER_OUT" ]; then
    echo "Missing 'opm render' output for the image" >&2
    exit 2
  fi

  if [ -z "$PACKAGE_NAME" ]; then
    echo "Missing package name" >&2
    exit 2
  fi

  # Jq query to extract unique bundles from `opm render` command output
  local jq_unique_bundles='select( .package == "'$PACKAGE_NAME'" ) | select(.schema == "olm.bundle") | select( [.properties[]|select(.type == "olm.deprecated")] == []) | "\(.image)"'
  echo "$RENDER_OUT" | tr -d '\000-\031' | jq -r "$jq_unique_bundles"
}

# Given output of `opm render` command and package name, this function returns
# all related images for the given package in the catalog
extract_related_images_from_catalog() {
  local RENDER_OUT="$1"
  local PACKAGE_NAME="$2"

  if [ -z "$RENDER_OUT" ]; then
    echo "Missing 'opm render' output for the image" >&2
    exit 2
  fi

  if [ -z "$PACKAGE_NAME" ]; then
    echo "Missing package name" >&2
    exit 2
  fi

  # Jq query to extract related images from `opm render` command output
  local jq_related_images='select( .package == "'$PACKAGE_NAME'" ) | select(.schema == "olm.bundle") | select( [.properties[]|select(.type == "olm.deprecated")] == []) | ["\(.relatedImages[]? | .image)"]'
  # flatten the lists into one and determine the unique values
  echo "$RENDER_OUT" | tr -d '\000-\031' | jq "$jq_related_images" | jq -s "flatten(1) | unique"
}

# Given output of `opm render` command and package name, this function returns
# unique package names in the catalog
extract_unique_package_names_from_catalog() {
  local RENDER_OUT="$1"

  if [ -z "$RENDER_OUT" ]; then
    echo "Missing 'opm render' output for the image" >&2
    exit 2
  fi

  echo "$RENDER_OUT" | tr -d '\000-\031' | jq -r 'select(.schema == "olm.package") | .name'
}

# This function will be used by tekton tasks in build-definitions
# It returns a list of unreleased bundles in the FBC fragment by comparing it with
# the corresponding production index image
get_unreleased_bundle() {
  # FBC fragment containing the unreleased bundle
  local FBC_FRAGMENT=""
  local INDEX_IMAGE="registry.redhat.io/redhat/redhat-operator-index"

  get_unreleased_bundle_usage()
  {
    echo "
  get_unreleased_bundle  -i FBC_FRAGMENT [-b INDEX_IMAGE]
  " >&2
    exit 2
  }

  local opt
  while getopts "i:b:" opt; do
      case "${opt}" in
          i)
              FBC_FRAGMENT="${OPTARG}" ;;
          b)
              INDEX_IMAGE="${OPTARG}" ;;
          *)
              get_unreleased_bundle_usage ;;
      esac
  done

  if [ -z "$FBC_FRAGMENT" ]; then
    echo "Missing parameter FBC_FRAGMENT" >&2
    exit 2
  fi

  # If the index image is provided and has a tag, remove it.
  # The target ocp version is determined from the fragment
  if [[ "$INDEX_IMAGE" == *:* ]]; then
    INDEX_IMAGE="${INDEX_IMAGE%%:*}"
  fi

  #Get target ocp version from the fragment
  local ocp_version
  if ! ocp_version=$(get_ocp_version_from_fbc_fragment "$FBC_FRAGMENT"); then
    echo "Could not get ocp version for the fragment" >&2
    exit 1
  fi

  # Run opm render on the FBC fragment to extract package names
  local render_out_fbc unique_bundles_fbc package_names
  if ! render_out_fbc=$(opm render "$FBC_FRAGMENT"); then
    echo "Could not render image $FBC_FRAGMENT" >&2
    exit 1
  fi
  package_names=$(extract_unique_package_names_from_catalog "$render_out_fbc")

  # Run opm render on the index image
  local render_out_index unique_bundles_index tagged_index
  tagged_index="${INDEX_IMAGE}:${ocp_version}"
  if ! render_out_index=$(opm render "$tagged_index"); then
    echo "Could not render image $tagged_index" >&2
    exit 1
  fi

  # Get unique bundles for each package from the fragment and the index
  for package_name in $package_names; do
    unique_bundles_fbc+="$(extract_unique_bundles_from_catalog "$render_out_fbc" "$package_name")"$'\n'
    unique_bundles_index+="$(extract_unique_bundles_from_catalog "$render_out_index" "$package_name")"$'\n'
  done

  # Compare the bundle lists and return the diff
  local unreleased_bundles
  unreleased_bundles=$(diff <(echo "$unique_bundles_fbc") <(echo "$unique_bundles_index") | grep '^<' | sed 's/^< //' | tr '\n' ' ')

  echo "${unreleased_bundles}" | tr ' ' '\n'

}

# This function will be used by tekton tasks in build-definitions
# It returns a list of unreleased related images as indicated in a FBC fragment.
# It compares the provided FBC fragment against the corresponding production index image
get_unreleased_fbc_related_images() {
  # FBC fragment containing the unreleased bundle
  local FBC_FRAGMENT=""
  local INDEX_IMAGE="registry.redhat.io/redhat/redhat-operator-index"

 get_unreleased_fbc_related_images_usage()
  {
    echo "
  get_unreleased_fbc_related_images  -i FBC_FRAGMENT [-b INDEX_IMAGE]
  " >&2
    exit 2
  }

  local opt
  while getopts "i:b:" opt; do
      case "${opt}" in
          i)
              FBC_FRAGMENT="${OPTARG}" ;;
          b)
              INDEX_IMAGE="${OPTARG}" ;;
          *)
              get_unreleased_fbc_related_images_usage ;;
      esac
  done

  if [ -z "$FBC_FRAGMENT" ]; then
    echo "Missing parameter FBC_FRAGMENT" >&2
    exit 2
  fi

  # If the index image is provided and has a tag, remove it.
  # The target ocp version is determined from the fragment
  if [[ "$INDEX_IMAGE" == *:* ]]; then
    INDEX_IMAGE="${INDEX_IMAGE%%:*}"
  fi

  #Get target ocp version from the fragment
  local ocp_version
  if ! ocp_version=$(get_ocp_version_from_fbc_fragment "$FBC_FRAGMENT"); then
    echo "Could not get ocp version for the fragment" >&2
    exit 1
  fi

  # Run opm render on the FBC fragment to extract package names
  local render_out_fbc unique_bundles_fbc package_names
  if ! render_out_fbc=$(opm render "$FBC_FRAGMENT"); then
    echo "Could not render image $FBC_FRAGMENT" >&2
    exit 1
  fi
  package_names=$(extract_unique_package_names_from_catalog "$render_out_fbc")

  # Run opm render on the index image
  local render_out_index unique_bundles_index tagged_index
  tagged_index="${INDEX_IMAGE}:${ocp_version}"
  if ! render_out_index=$(opm render "$tagged_index"); then
    echo "Could not render image $tagged_index" >&2
    exit 1
  fi

  # Get unique bundles for each package from the fragment and the index
  for package_name in $package_names; do
    related_images_fbc+="$(extract_related_images_from_catalog "$render_out_fbc" "$package_name")"$'\n'
    related_images_index+="$(extract_related_images_from_catalog "$render_out_index" "$package_name")"$'\n'
  done

  # Ensure that the jq arrays are flattened and unique
  related_images_fbc=$(echo "$related_images_fbc" | jq -s "flatten(1) | unique")
  related_images_index=$(echo "$related_images_index" | jq -s "flatten(1) | unique")

  # Get the images that are only in the fbc fragment
  local unreleased_related_images
  unreleased_related_images=$(jq -n --argjson released "$related_images_index" --argjson unreleased "$related_images_fbc" '{"released": $released,"unreleased":$unreleased} | .unreleased-.released')

  # output as json array
  echo -n "${unreleased_related_images}"

}

# This function will be used by tekton tasks in build-definitions
# It returns a list of labels on the image
get_image_labels() {
  local image=$1

  if [ -z "$image" ]; then
    echo "Missing image pull spec" >&2
    exit 2
  fi

  local image_labels
  if ! image_labels=$(skopeo inspect --config docker://"${image}"); then
    echo "Failed to inspect the image" >&2
    exit 1
  fi

  echo "${image_labels}" | jq -r '.config.Labels // {} | to_entries[] | "\(.key)=\(.value)"'

}

# This function will be used by tekton tasks in build-definitions
# It returns a list of relatedImages in the CSV of an operator bundle image
extract_related_images_from_bundle(){
  local image=$1

  if [ -z "$image" ]; then
    echo "Missing image pull spec" >&2
    exit 2
  fi

  local bundle_render_out related_images
  if ! bundle_render_out=$(opm render "${image}"); then
    echo "Failed to render the image" >&2
    exit 1
  fi
  related_images=$(echo "${bundle_render_out}" | tr -d '\000-\031' | jq -r '.relatedImages[]?.image')

  echo "${related_images}" | tr ' ' '\n'

}

# This function will be used by tasks in build-definitions
# It returns a map of {source: [mirror1, mirror2]} for imageDigestMirrorSet yaml
process_image_digest_mirror_set() {
  local yaml_input="$1"
  local pullspec_map="{"

  if ! echo "${yaml_input}" | yq '.' &>/dev/null; then
    echo "Invalid YAML input" >&2
    exit 2
  fi

  for entry in $(yq --output-format=json '.spec.imageDigestMirrors' <<<"${yaml_input}" | jq -c '.[]'); do
    source=$(echo "${entry}" | jq -r '.source')
    mirrors_list=$(echo "${entry}" | jq -r '.mirrors | map("\"" + . + "\"") | join(",")')
    pullspec_map+="\"${source}\":[${mirrors_list}],"
  done

  pullspec_map="${pullspec_map%,}}"

  echo "${pullspec_map}"

}

# This function will be used by tasks in build-definitions
# It replaces the image pullspec with the mirror and returns the modified pullspec
# The image should be in `<image>:<tag>`, `<image>@<digest>` or `<image>:<tag>@<digest>` format
replace_image_pullspec() {
  local image="$1"
  local mirror="$2"

  if [[ -z "$image" || -z "$mirror" ]]; then
    echo "Invalid input. Usage: replace_image_pullspec <image> <mirror>" >&2
    exit 2
  fi

  local image_regex="^([^:@]+)(:[^@]+)?(@sha256:[a-f0-9]{64})?$"
  if [[ "$image" =~ $image_regex ]]; then
    local digest=""
    if [[ "$image" =~ (@sha256:[a-f0-9]{64}) ]]; then
      digest=$(echo "$image" | sed -E 's/^.*(@sha256:[a-f0-9]{64})$/\1/')
      image=${image%%@*}
    fi

    local tag=""
    if [[ "$image" =~ (:[^@]+) ]]; then
      tag=$(echo "$image" | sed -E 's/^.*(:[^@]+).*$/\1/')
    fi

    echo "${mirror}${tag}${digest}"
  else
    echo "Invalid pullspec format: ${image}" >&2
    exit 2
  fi
}
