#!/usr/bin/env bash


# returns HACBS_TEST_OUTPUT json with predefined default. Function accepts optional args to modify result
# see make_result_json_usage for usage
make_result_json() {
  local RESULT=""
  local SUCCESSES=0
  local FAILURES=0
  local WARNINGS=0
  local NOTE="For more details please visit the logs in workspace of Tekton tasks."
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
    --arg date "$(date +%s)" \
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


# Return HACBS_TEST_OUTPUT error response
make_error_result_json(){
  # Note about error result for user
  local NOTE="$1"
  # Conftest namespace (should be empty in testcases without conftest)
  local NAMESPACE="$2"
  make_result_json -r 'ERROR' -t "${NOTE}" -n "${NAMESPACE}"
}


# Parse test result and genarate HACBS_TEST_OUTPUT
parse_hacbs_test_output() {
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
    HACBS_TEST_OUTPUT=$(make_result_json \
      -r "$(jq -rce '(if (.runs[].results | length > 0) then "FAILURE" else "SUCCESS" end)' "${TEST_RESULT_FILE}" || echo 'ERROR')" \
      -f "$(jq -rce '(.runs[].results | length)' "${TEST_RESULT_FILE}")" \
    )

    # Log out the failing runs
    if [ "$(echo "$HACBS_TEST_OUTPUT" | jq '.failures')" -gt 0 ]
    then
      echo "The $TEST_NAME test has failed with the following issues:"
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

    HACBS_TEST_OUTPUT=$(make_result_json \
      -r "$(jq -rce '.[] | (if (.failures | length > 0) then "FAILURE" else "SUCCESS" end)' "${TEST_RESULT_FILE}" || echo 'ERROR')" \
      -n "$(jq -rce '.[] | .namespace' "${TEST_RESULT_FILE}")" \
      -s "$(jq -rce '.[] | .successes' "${TEST_RESULT_FILE}")" \
      -f "$(jq -rce '.[] | (.failures | length)' "${TEST_RESULT_FILE}")" \
    )

    # Log out the failing runs
    if [ "$(echo "$HACBS_TEST_OUTPUT" | jq '.failures')" -gt 0 ]
    then
      echo "The $TEST_NAME test has failed with the following issues::"
      jq '.[].failures // []|map(.metadata.details.name) | unique' "$TEST_RESULT_FILE"
    fi    
  else
    echo "Unsupported TEST_RESULT_FORMAT $TEST_RESULT_FORMAT"
    exit 1
  fi
}
