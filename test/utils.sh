#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

OPM_RENDER_CACHE=/tmp/konflux-test-opm-cache
DEFAULT_INDEX_IMAGE="registry.redhat.io/redhat/redhat-operator-index"

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

# The function can be used to parse an image url. It will return a json
# object with keys:
#
# `registry_repository` - The repository of the image including an the registry and its optional port
# `tag` - The tag of the image reference
# `digest` - The digest of the image reference
#
# If an image tag or digest is not found then the values will be empty.
parse_image_url() {
  local image_url=$1

  if [ -z "$image_url" ]; then
    echo "parse_image_url: Missing positional parameter \$1 (image url)" >&2
    exit 2
  fi

  digest=""
  tag=""
  registry_repository="$(echo -n "$image_url" | cut -d@ -f1)"

  # Digest will be the last portion after an "@"
  at_number=$(echo -n "$image_url" | tr -cd "@" | wc -c | tr -d '[:space:]')
  colon_number=$(echo -n "$registry_repository" | tr -cd ":" | wc -c | tr -d '[:space:]')
  if [[ $at_number == 1 ]]; then
    digest="$(echo -n "${image_url}" | cut -d@ -f2)"
  elif [[ $at_number != 0 ]]; then
    # The only other supported format is registry/repository
    echo "parse_image_url: $image_url does not match the format registry(:port)/repository(:tag)(@digest)"
    exit 3
  fi

  # Isolate to find the tag and name
  # Trim off digest
  registry_repository="$(echo -n "$image_url" | cut -d@ -f1)"
  if [[ $colon_number == 2 ]]; then
    # format is now registry:port/repository:tag
    # trim off everything after the last colon
    tag=${registry_repository##*:}
    registry_repository=${registry_repository%:*}
  elif [[ $colon_number == 1 ]]; then
    # we have either a port or a tag so inspect the content after
    # the colon to determine if it is a valid tag.
    # https://github.com/opencontainers/distribution-spec/blob/main/spec.md
    # [a-zA-Z0-9_][a-zA-Z0-9._-]{0,127} is the regex for a valid tag
    # If not a valid tag, leave the colon alone.
    if [[ "$(echo -n "$registry_repository" | cut -d: -f2 | tr -d '[:space:]')" =~ ^([a-zA-Z0-9_][a-zA-Z0-9._-]{0,127})$ ]]; then
      # We match a tag so trim it off
      tag=$(echo -n "$registry_repository" | cut -d: -f2)
      registry_repository=$(echo -n "$registry_repository" | cut -d: -f1)
    fi
  elif [[ $colon_number != 0 ]]; then
    # The only other supported format is registry/repository
    echo "parse_image_url: $image_url does not match the format registry(:port)/repository(:tag)(@digest)"
    exit 3
  fi

  echo -n "{\"registry_repository\": \"$registry_repository\", \"tag\": \"$tag\", \"digest\": \"$digest\"}"
}

# Helper function to just get the pullspec in repository format
get_image_registry_and_repository() {
  local image_url=$1

  parse_image_url "$image_url" | jq -jr '.registry_repository'
}

# Helper function to just get the pullspec in repository:tag format
get_image_registry_repository_tag() {
  local image_url=$1

  parse_image_url "$image_url" | jq -jr '.registry_repository + if .tag != "" then ":" + .tag else "" end'
}

# Helper function to just get the pullspec in repository:tag@digest format
get_image_registry_repository_tag_digest() {
  local image_url=$1

 parse_image_url "$image_url" | jq -jr '.registry_repository + if .tag != "" then ":" + .tag else "" end + if .digest != "" then "@" + .digest else "" end'
}

# Helper function to just get the pullspec in repository@digest format
get_image_registry_repository_digest() {
  local image_url=$1

  parse_image_url "$image_url" | jq -jr '.registry_repository + if .digest != "" then "@" + .digest else "" end'
}

# The function will be used by the tekton tasks of build-definitions
# It returns a map of {arch:digest} for the given image_url
#
# The architecture and digest for an image manifest are not part of the
# spec: https://github.com/opencontainers/image-spec/blob/main/manifest.md
# Instead, architecture and digest are properties that buildah sets by default.
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
    echo "get_image_manifests: Missing keyword parameter (-i IMAGE_URL)" >&2
    exit 2
  fi

  # Ensure that we don't have a tag and digest for skopeo
  image_url=$(get_image_registry_repository_digest "$image_url")
  if ! raw_inspect_output=$(skopeo inspect --no-tags --raw docker://"${image_url}"); then
    echo "get_image_manifests: The raw image inspect command failed" >&2
    exit 1
  fi

  image_manifests=''
  if [ "$(echo "${raw_inspect_output}" | jq 'has("manifests")')" = "true" ]; then
    # We have an OCI image index, so return each of the included manifests
    image_manifests=$(echo "${raw_inspect_output}" | jq -rce ' .manifests | map ( {(.platform.architecture|tostring|ascii_downcase):  .digest} ) | add' )
  else
    if ! image_manifest_command_output=$(skopeo inspect --no-tags docker://"${image_url}"); then
      echo "get_image_manifests: The image manifest could not be inspected" >&2
      exit 1
    fi
    if [[ "$(echo "${image_manifest_command_output}" | jq 'has("Architecture")')" = "true" && "$(echo "${image_manifest_command_output}" | jq 'has("Digest")')" = "true" ]]; then
      image_manifests=$(echo "${image_manifest_command_output}" | jq -rce '{(.Architecture|tostring|ascii_downcase) : .Digest}')
    else
      echo "get_image_manifests: The image manifest does not have an architecture and digest" >&2
      exit 1
    fi
  fi

  echo "${image_manifests}"
}

# Get the repository:tag@digest for the base image as reported in the annotations
get_base_image() {
  local image="$1"

  if [ -z "$image" ]; then
    echo "get_base_image: Missing positional parameter \$1 (IMAGE)" >&2
    exit 2
  fi

  # Ensure that we have a digest-pinned image manifest
  image_manifest_digest=$(get_image_manifests -i "$image" | jq -er ".amd64")
  if [ -z "$image_manifest_digest" ]; then
    echo "get_base_image: manifest digest not found" >&2
    exit 1
  fi
  image_manifest=$(parse_image_url "$image" | jq -ej ".registry_repository + \"@$image_manifest_digest\"")

  # Get target ocp version from the fragment
  local ocp_version annotations
  annotations=$(get_image_annotations "$image_manifest")
  base_image=$(echo "$annotations" | grep 'org.opencontainers.image.base.name=' | cut -d= -f2 || true)
  base_image_digest=$(echo "$annotations" | grep 'org.opencontainers.image.base.digest=' | cut -d= -f2 || true)
  # It is okay if the digest doesn't exist
  if [ -z "$base_image" ]; then
    echo "get_base_image: base image annotation not found" >&2
    exit 1
  fi
  if [ -n "$base_image_digest" ]; then
    # While the digests should match, we want to ensure that we use the digest reported
    base_image="$(get_image_registry_repository_tag "$base_image")@$base_image_digest"
  fi
  echo -n "$base_image"
}

# This function will be used by tekton tasks in build-definitions
# It returns the ocp_version targeted by the FBC fragment
get_ocp_version_from_fbc_fragment() {
  local FBC_FRAGMENT="$1"

  if [ -z "$FBC_FRAGMENT" ]; then
    echo "get_ocp_version_from_fbc_fragment: Missing positional parameter \$1 (FBC_FRAGMENT)" >&2
    exit 2
  fi

  local base_image
  base_image=$(get_image_registry_repository_tag "$(get_base_image "$FBC_FRAGMENT")")
  ocp_version=$(parse_image_url "$base_image" | jq -ej '.tag')
  echo -n "$ocp_version"
}

# Given output of `opm render` command and package name, this function returns
# all unique bundles for the given package in the catalog
extract_unique_bundles_from_catalog() {
  local RENDER_OUT="$1"
  local PACKAGE_NAME="$2"

  if [ -z "$RENDER_OUT" ]; then
    echo "extract_unique_bundles_from_catalog: missing positional parameter \$1 (opm render output)" >&2
    exit 2
  fi

  if [ -z "$PACKAGE_NAME" ]; then
    echo "extract_unique_bundles_from_catalog: missing positional parameter \$2 (package name)" >&2
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
    echo "extract_related_images_from_catalog: missing positional parameter \$1 (opm render output)" >&2
    exit 2
  fi

  if [ -z "$PACKAGE_NAME" ]; then
    echo "extract_related_images_from_catalog: missing positional parameter \$2 (package name)" >&2
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
    echo "extract_unique_package_names_from_catalog: missing positional parameter \$1 (opm render output)" >&2
    exit 2
  fi

  echo "$RENDER_OUT" | tr -d '\000-\031' | jq -r 'select(.schema == "olm.package") | .name'
}

# This function can be used to get the target catalog image for a FBC fragment.
# context: https://konflux-ci.dev/architecture/ADR/0026-specifying-ocp-targets-for-fbc.html
get_target_fbc_catalog_image() {
  local FBC_FRAGMENT=""
  local INDEX_IMAGE="$DEFAULT_INDEX_IMAGE"

  get_target_fbc_catalog_image_usage()
  {
    echo "
  get_target_fbc_catalog_image -i FBC_FRAGMENT -b INDEX_IMAGE
  " >&2
    exit 2
  }

  local OPTIND opt
  while getopts "i:b:" opt; do
      case "${opt}" in
          i)
              FBC_FRAGMENT="${OPTARG}" ;;
          b)
              INDEX_IMAGE="${OPTARG}" ;;
          *)
              get_target_fbc_catalog_image_usage ;;
      esac
  done

  if [ -z "$FBC_FRAGMENT" ]; then
    echo "get_target_fbc_catalog_image: missing keyword parameter (-i FBC_FRAGMENT)" >&2
    exit 2
  fi

  if [ -z "$INDEX_IMAGE" ]; then
    echo "get_target_fbc_catalog_image: missing keyword parameter (-b INDEX_IMAGE)" >&2
    exit 2
  fi

  # If the index image is provided and has a tag, remove it.
  # The target ocp version is determined from the fragment
  INDEX_IMAGE=$(parse_image_url "$INDEX_IMAGE" | jq -jr '.registry_repository')

  #Get target ocp version from the fragment
  local ocp_version
  if ! ocp_version=$(get_ocp_version_from_fbc_fragment "$FBC_FRAGMENT"); then
    echo "get_target_fbc_catalog_image: could not get ocp version for the fragment" >&2
    exit 1
  fi
  
  echo "$INDEX_IMAGE:$ocp_version"
}

# This function can be used to render catalogs using a dedicated cache directory.
# It will make it easier to share processing of the catalogs within functions and
# outside of them.
# The OPM_RENDER_CACHE environment variable determines where to store the cache and
# rendered catalogs will be stored in a directory matching the index's digest.
render_opm() {
  local RENDER_TARGET=""

  render_opm_usage()
  {
    echo "
  render_opm -t RENDER_TARGET
  " >&2
    exit 2
  }

  local OPTIND opt
  while getopts "t:" opt; do
      case "${opt}" in
          t)
              RENDER_TARGET="${OPTARG}" ;;
          *)
              render_opm_usage ;;
      esac
  done

  if [ -z "$RENDER_TARGET" ]; then
    echo "render_opm: missing keyword parameter (-t RENDER_TARGET)" >&2
    exit 2
  fi

  local CACHE_DIR CACHE_SUBDIR RENDER_OUTPUT
  # shellcheck disable=SC2001
  CACHE_DIR=$(echo "$OPM_RENDER_CACHE" | sed 's:/*$::')
  # Ensure that the cache directory is present
  mkdir -p "$CACHE_DIR"
  CACHE_SUBDIR=$(parse_image_url "$RENDER_TARGET" | jq -jr '.registry_repository + if .tag != "" then "/" + .tag else "" end + if .digest != "" then "/" + .digest else "" end')
  if [[ -d "$CACHE_DIR/$CACHE_SUBDIR" ]]; then
    cat "$CACHE_DIR/$CACHE_SUBDIR/catalog"
  else
    if ! RENDER_OUTPUT=$(opm render "$RENDER_TARGET"); then
      echo "render_opm: could not render catalog $RENDER_TARGET" >&2
      exit 1
    fi
    mkdir -p "$CACHE_DIR/$CACHE_SUBDIR"
    echo "$RENDER_OUTPUT" | tee "$CACHE_DIR/$CACHE_SUBDIR/catalog"
  fi
}

# This helper function can be used to render and extract information from a FBC
# fragment and its matching index image (i.e according to the tag for the fragment's
# base image). 
# It will identify all packages in the FBC fragment and then apply a function on each
# of those packages in both the FBC fragment as well as the reference index.
# This function will return a list of content that is present in the FBC fragment but not
# in the target index according to the extraction operation provided.
# `-e unique_bundles` invokes extract_unique_bundles_from_catalog()
# `-e related_images` invokes extract_related_images_from_catalog()
extract_differential_fbc_metadata() {
  local EXTRACT_OPERATION=""
  local FBC_FRAGMENT=""
  local INDEX_IMAGE="$DEFAULT_INDEX_IMAGE"

  extract_differential_fbc_metadata_usage()
  {
    echo "
  extract_differential_fbc_metadata -i FBC_FRAGMENT -b INDEX_IMAGE -e EXTRACT_OPERATION
  " >&2
    exit 2
  }

  local OPTIND opt
  while getopts "i:b:e:" opt; do
      case "${opt}" in
          i)
              FBC_FRAGMENT="${OPTARG}" ;;
          b)
              INDEX_IMAGE="${OPTARG}" ;;
          e)
              EXTRACT_OPERATION="${OPTARG}" ;;
          *)
              extract_differential_fbc_metadata_usage ;;
      esac
  done

  if [ -z "$FBC_FRAGMENT" ]; then
    echo "extract_differential_fbc_metadata: missing keyword parameter (-i FBC_FRAGMENT)" >&2
    exit 2
  fi

  if [ -z "$EXTRACT_OPERATION" ]; then
    echo "extract_differential_fbc_metadata: missing keyword parameter (-e EXTRACT_OPERATION)" >&2
    exit 2
  fi

  if [ -z "$INDEX_IMAGE" ]; then
    echo "extract_differential_fbc_metadata: missing keyword parameter (-b INDEX_IMAGE)" >&2
    exit 2
  fi

  # Run opm render on the FBC fragment to extract package names
  local render_out_fbc package_names
  if ! render_out_fbc=$(render_opm -t "$FBC_FRAGMENT"); then
    echo "extract_differential_fbc_metadata: could not render FBC fragment $FBC_FRAGMENT" >&2
    exit 1
  fi
  package_names=$(extract_unique_package_names_from_catalog "$render_out_fbc")

  # Run opm render on the matching index image
  local render_out_index tagged_index
  if ! tagged_index=$(get_target_fbc_catalog_image -i "$FBC_FRAGMENT" -b "$INDEX_IMAGE"); then
    echo "extract_differential_fbc_metadata: could not get a matching catalog image" >&2
    exit 1
  fi
  if ! render_out_index=$(render_opm -t "$tagged_index"); then
    echo "extract_differential_fbc_metadata: could not render index image $tagged_index" >&2
    exit 1
  fi

  local package_result_fbc package_result_index
  # Get unique bundles for each package from the fragment and the index
  if [[ "$EXTRACT_OPERATION" == "unique_bundles" ]]; then
    for package_name in $package_names; do
      package_result_fbc+="$(extract_unique_bundles_from_catalog "$render_out_fbc" "$package_name") "
      package_result_index+="$(extract_unique_bundles_from_catalog "$render_out_index" "$package_name") "
    done
  elif [[ "$EXTRACT_OPERATION" == "related_images" ]]; then
    for package_name in $package_names; do
      package_result_fbc+="$(extract_related_images_from_catalog "$render_out_fbc" "$package_name") "
      package_result_index+="$(extract_related_images_from_catalog "$render_out_index" "$package_name") "
    done
  else
    echo "extract_differential_fbc_metadata: extract operation $EXTRACT_OPERATION not supported: [unique_bundles, related_images]" >&2
    exit 1
  fi

  # Ensure that the jq arrays are flattened and unique. The process is different for each operation
  if [[ "$EXTRACT_OPERATION" == "unique_bundles" ]]; then
    unique_fbc=$(echo "$package_result_fbc" | tr '\n' ' ' | jq -Rc 'split(" ") | map(select(length > 0))')
    unique_index=$(echo "$package_result_index" | tr '\n' ' ' | jq -Rc 'split(" ") | map(select(length > 0))')
  elif [[ "$EXTRACT_OPERATION" == "related_images" ]]; then
    unique_fbc=$(echo "$package_result_fbc" | jq -s "flatten(1) | unique")
    unique_index=$(echo "$package_result_index" | jq -s "flatten(1) | unique")
  fi

  # Store JSON variables into temporary files to avoid "/usr/bin/jq: Argument list too long"
  echo "$unique_index" > /tmp/unique_index.json
  echo "$unique_fbc" > /tmp/unique_fbc.json

  # Get the images that are only in the fbc fragment
  local unreleased_result
  unreleased_result=$(jq -n \
    --slurpfile released /tmp/unique_index.json \
    --slurpfile unreleased /tmp/unique_fbc.json \
    '{"released": $released[0], "unreleased": $unreleased[0]} | .unreleased - .released')

  # Cleanup temporary files
  rm -f /tmp/unique_index.json /tmp/unique_fbc.json

  echo "$unreleased_result"
}

# This function will be used by tekton tasks in build-definitions
# It returns a newline-delimited list of unreleased bundles in the FBC fragment by
# comparing it with the corresponding production index image
get_unreleased_bundles() {
  # Parse input here to return usage message if needed
  local FBC_FRAGMENT=""
  local INDEX_IMAGE="$DEFAULT_INDEX_IMAGE"
  get_unreleased_bundles_usage()
  {
    echo "
  get_unreleased_bundles -i FBC_FRAGMENT [-b INDEX_IMAGE]
  " >&2
    exit 2
  }

  local OPTIND opt
  while getopts "i:b:" opt; do
      case "${opt}" in
          i)
              FBC_FRAGMENT="${OPTARG}" ;;
          b)
              INDEX_IMAGE="${OPTARG}" ;;
          *)
              get_unreleased_bundles_usage ;;
      esac
  done

  if [ -z "$FBC_FRAGMENT" ]; then
    echo "get_unreleased_bundles: missing keyword parameter (-i FBC_FRAGMENT)" >&2
    exit 2
  fi

  result=$(extract_differential_fbc_metadata -i "$FBC_FRAGMENT" -b "$INDEX_IMAGE" -e "unique_bundles")
  result_exit=$?

  if [[ "$result_exit" != "0" ]]; then
    exit $result_exit
  fi

  # Convert output from a json array to a newline delimited list
  echo "${result}" | jq -r '.[]'
}
# Maintaining backwards compatibility, this function just passes through to the other.
# get_unreleased_bundles was renamed for consistency
get_unreleased_bundle() {
  get_unreleased_bundles "$@"
}

# This function will be used by tekton tasks in build-definitions
# It returns a json array of unreleased related images as indicated in a FBC fragment.
# It compares the provided FBC fragment against the corresponding production index image
get_unreleased_fbc_related_images() {
  # Parse input here to return usage message if needed
  local FBC_FRAGMENT=""
  local INDEX_IMAGE="$DEFAULT_INDEX_IMAGE"
  get_unreleased_fbc_related_images_usage()
  {
    echo "
  get_unreleased_fbc_related_images -i FBC_FRAGMENT [-b INDEX_IMAGE]
  " >&2
    exit 2
  }

  local OPTIND opt
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
    echo "get_unreleased_fbc_related_images: missing keyword parameter (-i FBC_FRAGMENT)" >&2
    exit 2
  fi

  result=$(extract_differential_fbc_metadata -i "$FBC_FRAGMENT" -b "$INDEX_IMAGE" -e related_images)
  result_exit=$?

  if [[ "$result_exit" != "0" ]]; then
    exit $result_exit
  fi

  # result is already a json array, so just output it directly
  echo -n "${result}"
}

# This function will be used by tekton tasks in build-definitions
# It returns a list of labels on the image
get_image_labels() {
  local image=$1

  if [ -z "$image" ]; then
    echo "get_image_labels: missing positional parameter \$1 (image pull spec)" >&2
    exit 2
  fi

  local image_labels
  # Ensure that we don't have a tag and digest for skopeo
  image=$(get_image_registry_repository_digest "$image")
  if ! image_labels=$(skopeo inspect --no-tags docker://"${image}"); then
    echo "get_image_labels: failed to inspect the image" >&2
    exit 1
  fi

  echo "${image_labels}" | jq -jr '.Labels // {} | to_entries[] | "\(.key)=\(.value)\n"'
}

# This function will be used by tekton tasks in build-definitions
# It returns a list of annotations on the image
# If no annotations exist, it returns an empty string
get_image_annotations() {
  local image=$1

  if [ -z "$image" ]; then
    echo "get_image_annotations: missing positional parameter \$1 (image pull spec)" >&2
    exit 2
  fi

  # Ensure that we don't have a tag and digest for skopeo
  image=$(get_image_registry_repository_digest "$image")

  local image_annotations
  if ! image_annotations=$(skopeo inspect --no-tags --raw docker://"${image}"); then
    echo "get_image_annotations: failed to inspect the image" >&2
    exit 1
  fi
  echo "${image_annotations}" | jq -jr 'if .annotations != null then .annotations | to_entries[] | "\(.key)=\(.value)\n" else "" end'
}

# This function will be used by tekton tasks in build-definitions
# It returns a list of relatedImages in the CSV of an operator bundle image
extract_related_images_from_bundle(){
  local image=$1

  if [ -z "$image" ]; then
    echo "extract_related_images_from_bundle: missing positional parameter \$1 (image pull spec)" >&2
    exit 2
  fi

  local bundle_render_out jq_related_images related_images
  if ! bundle_render_out=$(render_opm -t "${image}"); then
    echo "extract_related_images_from_bundle: failed to render the image ${image}" >&2
    exit 1
  fi
  # opm render on a bundle will always add the bundle. We want to make sure that
  # we strip that out.
  jq_related_images='[.relatedImages[]?.image] - ["'${image}'"] | .[]'
  related_images=$(echo "${bundle_render_out}" | tr -d '\000-\031' | jq -r "$jq_related_images")

  echo "${related_images}" | tr ' ' '\n'
}

# This function will be used by tasks in build-definitions
# It returns a map of {source: [mirror1, mirror2]} for imageDigestMirrorSet yaml
process_image_digest_mirror_set() {
  local yaml_input="$1"
  local pullspec_map="{"

  if ! echo "${yaml_input}" | yq '.' &>/dev/null; then
    echo "process_image_digest_mirror_set: Invalid YAML input" >&2
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
    echo "replace_image_pullspec: Usage: replace_image_pullspec <image> <mirror>" >&2
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
    echo "replace_image_pullspec: invalid pullspec format: ${image}" >&2
    exit 2
  fi
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $fbc_fragment' command, this function returns a package name
# If there is only one 'olm.package', it returns it's name
# If there are multiple 'olm.package' entries, it returns the one with the highest bundle version in the package’s 'defaultChannel'
get_package_from_catalog() {
  local RENDER_OUT_FBC="$1"
  local package_count
  local package_name

  if [ -z "$RENDER_OUT_FBC" ]; then
    echo "get_package_from_catalog: Missing 'opm render' output for the image" >&2
    exit 2
  fi

  # Count 'olm.package' entries in the rendered FBC output
  package_count=$(echo "$RENDER_OUT_FBC" | tr -d '\000-\031' | jq -s '[.[] | select(.schema == "olm.package")] | length')

  if [[ "$package_count" -eq 1 ]]; then
    # Return the single package name
    package_name=$(echo "$RENDER_OUT_FBC" | tr -d '\000-\031' | jq -r 'select(.schema == "olm.package") | .name')
    echo "$package_name"
  else
    # Handle multiple packages
    # Find the highest bundle version for each package based on the entries in their respective defaulChannel
    package_name=$(echo "$RENDER_OUT_FBC" | tr -d '\000-\031' | jq -r '
    reduce inputs as $obj (
      {
        packages: [],
        channels: []
      };
      if $obj.schema == "olm.package" then
        .packages += [$obj]
      elif $obj.schema == "olm.channel" then
        .channels += [$obj]
      else . end
    ) | 
    .packages[] as $pkg |
    (.channels[] | select(.package == $pkg.name and .name == $pkg.defaultChannel)) as $channel |
    ($channel.entries | map({
        name: .name,
        version: (.name | split(".") | map(try tonumber // 0))
    }) | max_by(.version)) as $highest |
    if $highest.name then $pkg.name else empty end
  ')
    echo "$package_name"
  fi
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $fbc_fragment' command and a package name, this function returns the defaultChannel value specified in the olm.package entry
get_channel_from_catalog() {
  local RENDER_OUT_FBC="$1"
  local PACKAGE_NAME="$2"
  local default_channel

  if [[ -z "$RENDER_OUT_FBC" || -z "$PACKAGE_NAME" ]]; then
    echo "get_channel_from_catalog: Invalid input. Usage: get_channel_from_catalog <RENDER_OUT_FBC> <PACKAGE_NAME>" >&2
    exit 2
  fi

  # Extract the defaultChannel for a given package
  default_channel=$(echo "$RENDER_OUT_FBC" | tr -d '\000-\031' | jq -r --arg PACKAGE_NAME "$PACKAGE_NAME" '
    select(.schema == "olm.package" and .name == $PACKAGE_NAME) | .defaultChannel
  ')

  # Handle case when PACKAGE_NAME is not found in RENDER_OUT_FBC
  if [[ -z "$default_channel" || "$default_channel" == "null" ]]; then
    echo "get_channel_from_catalog: Package name $PACKAGE_NAME not found in the rendered FBC" >&2
    exit 1
  fi

  echo "$default_channel"
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $fbc_fragment' command, a package name, and a channel name this function returns the highest bundle version
get_highest_bundle_version() {
  local RENDER_OUT_FBC="$1"
  local PACKAGE_NAME="$2"
  local CHANNEL_NAME="$3"

  # Validate input parameters
  if [[ -z "$RENDER_OUT_FBC" || -z "$PACKAGE_NAME" || -z "$CHANNEL_NAME" ]]; then
    echo "get_highest_bundle_version: Invalid input. Usage: get_highest_bundle_version <RENDER_OUT_FBC> <PACKAGE_NAME> <CHANNEL_NAME>" >&2
    exit 2
  fi

  # Extract the highest bundle version
  local highest_bundle
  highest_bundle=$(echo "$RENDER_OUT_FBC" | jq -r --arg package "$PACKAGE_NAME" --arg channel "$CHANNEL_NAME" '
    select(.schema == "olm.channel" and .package == $package and .name == $channel) |
    .entries | map({
      name: .name,
      version: (.name | split(".") | map(try tonumber // 0))
    }) | max_by(.version) | .name
  ')

  # Check if a bundle version was found
  if [[ -z "$highest_bundle" || "$highest_bundle" == "null" ]]; then
    echo "get_highest_bundle_version: No valid bundle version found for package: $PACKAGE_NAME, channel: $CHANNEL_NAME" >&2
    exit 1
  fi

  # Find the corresponding image name for the highest bundle
  local bundle_image
  bundle_image=$(echo "$RENDER_OUT_FBC" | jq -r --arg bundle "$highest_bundle" '
    select(.schema == "olm.bundle" and .name == $bundle) | .image
  ')

  # Check if an image was found
  if [[ -z "$bundle_image" || "$bundle_image" == "null" ]]; then
    echo "get_highest_bundle_version: No image found for bundle: $highest_bundle" >&2
    exit 1
  fi

  echo "$bundle_image"
}
