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
  if ! raw_inspect_output=$(retry skopeo inspect --no-tags --raw docker://"${image_url}"); then
    echo "get_image_manifests: The raw image inspect command failed" >&2
    exit 1
  fi

  image_manifests=''
  if [ "$(echo "${raw_inspect_output}" | jq 'has("manifests")')" = "true" ]; then
    # We have an OCI image index, so return each of the included manifests
    image_manifests=$(echo "${raw_inspect_output}" | jq -rce ' .manifests | map ( {(.platform.architecture|tostring|ascii_downcase):  .digest} ) | add' )
  else
    if ! image_manifest_command_output=$(retry skopeo inspect --no-tags docker://"${image_url}"); then
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

  # Ensure that we have a digest-pinned image manifest. For image manifests of archs other than amd64,
  # grab the first value in the map.
  local image_manifests
  image_manifests=$(get_image_manifests -i "$image")
  image_manifest_digest=$(echo "$image_manifests" | jq -er ".amd64 // (to_entries | .[0].value)" || echo "")
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
  if [ -z "${ocp_version}" ]; then
    echo "get_ocp_version_from_fbc_fragment: No ocp version found; base image tag is empty." >&2
    exit 2
  fi
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
  echo "$RENDER_OUT" | tr -d '\000-\031' | jq -r "$jq_unique_bundles" | jq -Rc 'split("\n")'
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
    if ! RENDER_OUTPUT=$(retry opm render "$RENDER_TARGET"); then
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
# 
# Additional extract operations added should return the results as JSON arrays so that
# we can have a common post-processing behavior.
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

  # Get unique bundles for each package from the fragment and the index
  if [[ "$EXTRACT_OPERATION" == "unique_bundles" ]]; then
    for package_name in $package_names; do
      extract_unique_bundles_from_catalog "$render_out_fbc" "$package_name" >> /tmp/unique_fbc.json
      extract_unique_bundles_from_catalog "$render_out_index" "$package_name" >> /tmp/unique_index.json
    done
  elif [[ "$EXTRACT_OPERATION" == "related_images" ]]; then
    for package_name in $package_names; do
      extract_related_images_from_catalog "$render_out_fbc" "$package_name" >> /tmp/unique_fbc.json
      extract_related_images_from_catalog "$render_out_index" "$package_name" >> /tmp/unique_index.json
    done
  else
    echo "extract_differential_fbc_metadata: extract operation $EXTRACT_OPERATION not supported: [unique_bundles, related_images]" >&2
    exit 1
  fi

  # The output of the unique fbc and index files will be a set of arrays. We need to
  # post-process them so that we can use bash commands instead of jq commands. This
  # includes removing all commas, braces, and whitespace; sorting the lists; and ensuring values
  # are unique.
  sed -i 's/,//;s/\[//;s/\]//;s/[[:space:]]*//' /tmp/unique_fbc.json /tmp/unique_index.json
  sort -u -o /tmp/unique_fbc.json /tmp/unique_fbc.json
  sort -u -o /tmp/unique_index.json /tmp/unique_index.json

  # Get the images that are only in the fbc fragment. We previously used jq to slurp
  # in these files and subtract the lists. That was consuming too much memory. Instead,
  # we will just keep the lists as files. Use `comm` to compare the sorted files. This
  # will end up creating an invalid array, so we need to massage the contents back to
  # return it to be a valid array
  comm -13 /tmp/unique_index.json /tmp/unique_fbc.json > /tmp/unreleased_result

  # Now that we have a list of unique results, let's convert it back to a json array by
  # adding a comma to the end of every line but the last and surrounding it with braces
  # as we return it
  sed -i '$!s/$/,/' /tmp/unreleased_result
  echo "[$(cat /tmp/unreleased_result)]"

  # Cleanup temporary files
  rm -f /tmp/unique_index.json /tmp/unique_fbc.json /tmp/unreleased_result
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
  if ! image_labels=$(retry skopeo inspect --no-tags docker://"${image}"); then
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
  if ! image_annotations=$(retry skopeo inspect --no-tags --raw docker://"${image}"); then
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

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $bundle_image' command, this function returns the supported architectures for the bundle
get_bundle_arches() {
  local RENDER_OUT_BUNDLE="$1"
  local arches

  # Validate input parameters
  if [[ -z "$RENDER_OUT_BUNDLE" ]]; then
    echo "get_bundle_arches: Invalid input. Usage: get_bundle_arches <RENDER_OUT_BUNDLE>" >&2
    exit 2
  fi

  arches=$(echo "$RENDER_OUT_BUNDLE" | tr -d '\000-\031' | jq -r '
    .properties[]
    | select(.type == "olm.csv.metadata")
    | (.value.labels // {})
    | to_entries[]
    | select(.value == "supported").key
    | scan("^operatorframework.io/arch.\\K.*")
  ')

  if [[ -z "$arches" ]]; then
    echo "get_bundle_arches: Error: No architectures found for bundle image." >&2
    exit 1
  fi

  echo "$arches"
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $fbc_fragment, and bundle images, this function groups bundle images by package
# It returns a map in the format {"package1":["bundleImage1","bundleImage2"],"package2":["bundleImage3"]}
group_bundle_images_by_package() {
  local RENDER_OUT_FBC="$1"
  local BUNDLE_IMAGES="$2"
  local package_image_map

  # Validate input parameters
  if [[ -z "$RENDER_OUT_FBC" || -z "$BUNDLE_IMAGES" ]]; then
    echo "group_bundle_images_by_package: Invalid input. Usage: group_bundle_images_by_package <RENDER_OUT_FBC> <BUNDLE_IMAGES>" >&2
    exit 2
  fi

  # Group bundle images by package
  package_image_map=$(echo "$RENDER_OUT_FBC" | tr -d '\000-\031' | jq -cs \
    --argjson bundles "$(printf '%s\n' "${BUNDLE_IMAGES[@]}" | jq -R . | jq -s .)" \
    '[.[] | select(.schema == "olm.bundle" and (.image as $img | $bundles | index($img) != null))] |
      group_by(.package) |
      map({(.[0].package): [.[].image]}) | add')

  # Check if package_image_map is empty or null
  if [[ -z "$package_image_map" || "$package_image_map" == "null" || "$package_image_map" == "{}" ]]; then
    echo "group_bundle_images_by_package: No matching packages found for the provided bundle images." >&2
    exit 1
  fi

  echo "$package_image_map"
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $fbc_fragment' command, a package name, a channel name, and a bundle images list this function returns the highest bundle version from the provided BUNDLE_IMAGES list
get_highest_version_from_bundles_list() {
  local RENDER_OUT_FBC="$1"
  local PACKAGE_NAME="$2"
  local CHANNEL_NAME="$3"
  local BUNDLE_IMAGES="$4"

  # Validate input parameters
  if [[ -z "$RENDER_OUT_FBC" || -z "$PACKAGE_NAME" || -z "$CHANNEL_NAME" || -z "$BUNDLE_IMAGES" ]]; then
    echo "get_highest_version_from_bundles_list: Invalid input. Usage: get_highest_version_from_bundles_list <RENDER_OUT_FBC> <PACKAGE_NAME> <CHANNEL_NAME> <BUNDLE_IMAGES>" >&2
    exit 2
  fi

  # Extract bundle names from `olm.channel`
  local bundle_names_from_channel
  bundle_names_from_channel=$(echo "$RENDER_OUT_FBC" | jq -nc --arg PACKAGE_NAME "$PACKAGE_NAME" --arg CHANNEL_NAME "$CHANNEL_NAME" '
    [inputs | select(.schema == "olm.channel" and .package == $PACKAGE_NAME and .name == $CHANNEL_NAME)
    | .entries[].name] | unique')

  # Extract bundles from `olm.bundle` matching given BUNDLE_IMAGES list
  local valid_bundles
  valid_bundles=$(echo "$RENDER_OUT_FBC" | jq -nc --argjson bundle_names "$bundle_names_from_channel" --argjson images "$(echo "$BUNDLE_IMAGES" | jq -R -s -c 'split("\n") | map(select(length > 0))')" '
    [inputs | select(.schema == "olm.bundle" and (.name | IN($bundle_names[])) and (.image | IN($images[])))
    | { version: (.name | capture("v(?<version>[0-9]+\\.[0-9]+\\.[0-9]+(-[0-9]+)?)$").version // "0"), image: .image }]')

  # Exit if no valid bundles found
  if [[ -z "$valid_bundles" || "$valid_bundles" == "[]" ]]; then
    echo "get_highest_version_from_bundles_list: No matching bundle versions found in the provided image list." >&2
    exit 1
  fi

  # Find the highest version and its corresponding image
  local highest_image
  highest_image=$(echo "$valid_bundles" | jq -r '
    max_by(.version | split("-") | map(split(".") | map(tonumber)) | flatten) | .image')

  echo "$highest_image"
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $bundle_image' command, this function returns the suggested namespace for the bundle
get_bundle_suggested_namespace() {
  local RENDER_OUT_BUNDLE="$1"

  # Validate input parameters
  if [[ -z "$RENDER_OUT_BUNDLE" ]]; then
    echo "get_bundle_suggested_namespace: Invalid input. Usage: get_bundle_suggested_namespace <RENDER_OUT_BUNDLE>" >&2
    exit 2
  fi

  # Check if 'olm.csv.metadata' exists in the bundle
  local metadata_exists
  metadata_exists=$(echo "$RENDER_OUT_BUNDLE" | tr -d '\000-\031' | jq -e '
    any(.properties[]?; .type == "olm.csv.metadata")' 2>/dev/null)

  if [[ "$metadata_exists" != "true" ]]; then
    echo "get_bundle_suggested_namespace: No 'olm.csv.metadata' entry found in bundle properties" >&2
    exit 1
  fi

  local namespace
  namespace=$(echo "$RENDER_OUT_BUNDLE" | tr -d '\000-\031' | jq -r '
    .properties[]? 
    | select(.type == "olm.csv.metadata" and (.value | type == "object"))
    | .value.annotations["operatorframework.io/suggested-namespace"]')

  echo "$namespace"
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $bundle_image' command, this function returns the supported install modes for the bundle
get_bundle_install_modes() {
  local RENDER_OUT_BUNDLE="$1"

  # Validate input parameters
  if [[ -z "$RENDER_OUT_BUNDLE" ]]; then
    echo "get_bundle_install_modes: Invalid input. Usage: get_bundle_install_modes <RENDER_OUT_BUNDLE>" >&2
    exit 2
  fi

  # Check if 'olm.csv.metadata' exists in the bundle
  local metadata_exists
  metadata_exists=$(echo "$RENDER_OUT_BUNDLE" | tr -d '\000-\031' | jq -e '
    any(.properties[]?; .type == "olm.csv.metadata")' 2>/dev/null)

  if [[ "$metadata_exists" != "true" ]]; then
    echo "get_bundle_install_modes: No 'olm.csv.metadata' entry found in bundle properties" >&2
    exit 1
  fi

  local install_modes
  install_modes=$(echo "$RENDER_OUT_BUNDLE" | tr -d '\000-\031' | jq -r '
    .properties[]? 
    | select(.type == "olm.csv.metadata") 
    | .value.installModes[]? 
    | select(.supported == true) 
    | .type')

  # Ensure install modes are not empty
  if [[ -z "$install_modes" ]]; then
    echo "get_bundle_install_modes: No supported install modes found in bundle" >&2
    exit 1
  fi

  echo "$install_modes"
}

# This function will be used by tasks in tekton-integration-catalog
# Given the output of 'opm render $bundle_image' command, this function returns the name of the bundle
get_bundle_name() {
  local RENDER_OUT_BUNDLE="$1"

  # Validate input parameters
  if [[ -z "$RENDER_OUT_BUNDLE" ]]; then
    echo "get_bundle_name: Invalid input. Usage: get_bundle_name <RENDER_OUT_BUNDLE>" >&2
    exit 2
  fi

  local bundle_name
  bundle_name=$(echo "$RENDER_OUT_BUNDLE" | tr -d '\000-\031' | jq -r '.name')

  # Ensure the bundle name is not empty
  if [[ -z "$bundle_name" || "$bundle_name" == "null" ]]; then
    echo "get_bundle_name: No bundle name found" >&2
    exit 1
  fi

  echo "$bundle_name"
}

# Retry a given command RETRY_COUNT times, defaults to 3.
# Retry stops once the expected exit status is encountered.
# Expected exit status is given in the first positional argument.
retry() {
  local status
  local retry=0
  local -r interval=${RETRY_INTERVAL:-5}
  local -r max_retries=${RETRY_COUNT:-3}
  local expected_status
  if grep -q "^[[:digit:]]\+$" <<<"$1"; then
      expected_status=$1
      shift
  fi
  while true; do
      "$@" && break
      status=$?
      if [[ -v expected_status ]] && [[ ${status} -eq ${expected_status} ]]; then
          return ${status}
      fi
      ((retry+=1))
      if [ "${retry}" -gt "${max_retries}" ]; then
          return "${status}"
      fi
      echo "info: Retrying again in ${interval} seconds..." 1>&2
      sleep "${interval}"
  done
}

# This function will be used by tasks in tekton-integration-catalog
# Update the image digest with the 0th manifest
resolve_to_0th_manifest_digest() {
  local image_url="$1"

  # Validate input parameters
  if [[ -z "$image_url" ]]; then
    echo "resolve_to_0th_manifest_digest: Invalid input. Usage: resolve_to_0th_manifest_digest <image_url>" >&2
    exit 2
  fi

  # Get image manifests as a map of {arch:digest}
  local manifests
  manifests=$(get_image_manifests -i "$image_url")

  # Extract 0th manifest's digest
  local new_digest
  new_digest=$(echo "$manifests" | jq -r 'to_entries[0].value')

  # Remove an existing digest from the original image
  local image_no_digest
  image_no_digest=$(get_image_registry_repository_tag "$image_url")

  echo -n "${image_no_digest}@${new_digest}"
}

# This function will be used by tasks in tekton-integration-catalog
# Given an image mirror set yaml, it transforms the YAML into a single-line string where each entry is separated by \n and indentation is preserved using spaces.
serialize_image_mirrors_yaml() {
  local yaml_input="$1"

  # Validate YAML input string
  if ! echo "${yaml_input}" | yq '.' &>/dev/null; then
    echo "serialize_image_mirrors_yaml: Invalid YAML input" >&2
    return 2
  fi

  # Extract and format as escaped string
  local serialized_mirrors
  serialized_mirrors=$(yq --output-format=json '.spec.imageDigestMirrors' <<<"${yaml_input}" |
    jq -r '.[] |
      "- mirrors:\n    - " + (.mirrors | join("\n    - ")) + "\n  source: " + .source' |
    paste -sd'\n' - |
    sed ':a;N;$!ba;s/\n/\\n/g')
  
  echo "${serialized_mirrors}"
}

# This function will be used by tasks in tekton-integration-catalog
# Given a plain text file of image pull event logs and a deployment start timestamp, this function returns the images that were pulled on or after the specified timestamp.
# The input file should contain lines similar to the output of `oc get events` or `kubectl get events`, such as: '2025-06-10T08:15:52Z,Pulling image "quay.io/example/image:tag"'
# The timestamp must be in ISO 8601 format (e.g., 2025-06-10T08:15:52Z).
parse_collected_image_pulls() {
  local image_pull_events_file="$1"
  local deployment_start_time="$2"

  # Validate input parameters
  if [[ -z "$image_pull_events_file" || -z "$deployment_start_time" ]]; then
    echo "parse_collected_image_pulls: Invalid input. Usage: parse_collected_image_pulls <image_pull_events_file> <deployment_start_time>" >&2
    exit 2
  fi

  awk -v start="$deployment_start_time" -F',' '
    {
      if ($1 >= start) {
        match($2, /image "[^"]+"/, arr)
        if (arr[0] != "") {
          gsub(/image "|"/, "", arr[0])
          images[arr[0]]
        }
      }
    }
    END {
      for (img in images) {
        print img
      }
    }
  ' "$image_pull_events_file" | sort
}

# This function will be used by tasks in tekton-integration-catalog
# Given a scorecard config yaml, this function extracts unique image references defined under .stages[].tests[].image.
# It returns a sorted list of these unique image references, one per line.
collect_scorecard_config_images() {
  local yaml_input="$1"
  local images=()

  if ! echo "${yaml_input}" | yq '.' &>/dev/null; then
    echo "collect_scorecard_config_images: Invalid YAML input" >&2
    return 2
  fi

  local stage_count
  stage_count=$(echo "$yaml_input" | yq -r '.stages | length' 2>/dev/null)

  # Return early if no stages key or empty
  if [[ -z "$stage_count" || "$stage_count" == "null" || "$stage_count" -eq 0 ]]; then
    return 0
  fi

  for (( i=0; i<stage_count; i++ )); do
    local test_count
    test_count=$(echo "$yaml_input" | yq -r ".stages[$i].tests | length" 2>/dev/null)

    if [[ -z "$test_count" || "$test_count" == "null" || "$test_count" -eq 0 ]]; then
      continue
    fi

    for (( j=0; j<test_count; j++ )); do
      local image
      image=$(echo "$yaml_input" | yq -r ".stages[$i].tests[$j].image")

      if [[ -n "$image" && "$image" != "null" ]]; then
        images+=("$image")
      fi
    done
  done

  if (( ${#images[@]} > 0 )); then
    printf "%s\n" "${images[@]}" | sort -u
  fi
}
