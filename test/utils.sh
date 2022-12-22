#!/bin/sh -l

# Parse test result and genarate HACBS_TEST_OUTPUT
parse_hacbs_test_output() {
  # The name of test
  TEST_NAME=$1
  # The format of json file, can be conftest or sarif
  TEST_RESULT_FORMAT=$2
  # The json file to parse
  TEST_RESULT_FILE=$3

  if [ -z "$TEST_NAME" ]; then
    echo Missing parameter TEST_NAME
    exit 1
  fi
  if [ -z "$TEST_RESULT_FORMAT" ]; then
    echo Missing parameter TEST_RESULT_FORMAT
    exit 1
  fi
  if [ -z "$TEST_RESULT_FILE" ]; then
    echo Missing parameter TEST_RESULT_FILE
    exit 1
  fi

  if [ ! -f "$TEST_RESULT_FILE" ]; then
    echo "File $TEST_RESULT_FILE doesn't exist"
    exit 1
  fi

  # Handle the test result with format of sarif
  if [ "$TEST_RESULT_FORMAT" = "sarif" ]; then
    HACBS_TEST_OUTPUT=$(jq -rce --arg date $(date +%s)  \
      '{ result: (if (.runs[].results | length > 0) then "FAILURE" else "SUCCESS" end),
               timestamp: $date,
               namespace: "default",
               successes: 0,
               note: "",
               failures: (.runs[].results | length)
             }' $TEST_RESULT_FILE || true)

    # Log out the failing runs
    if [ $(echo $HACBS_TEST_OUTPUT | jq '.failures') -gt 0 ]
    then
      echo "The $TEST_NAME test has failed with the following issues:"
      jq '.runs[].results // []|map(.message.text) | unique' $TEST_RESULT_FILE
    fi
  # Handle the test result with format of conftest
  elif [ "$TEST_RESULT_FORMAT" = "conftest" ]; then
    HACBS_TEST_OUTPUT=$(jq -rce --arg date $(date +%s) \
      '.[] | { result: (if (.failures | length > 0) then "FAILURE" else "SUCCESS" end),
               timestamp: $date,
               namespace,
               successes,
               failures: (.failures | length)
             }' $TEST_RESULT_FILE || true)

    # Log out the failing runs
    if [ $(echo $HACBS_TEST_OUTPUT | jq '.failures') -gt 0 ]
    then
      echo "The $TEST_NAME test has failed with the following issues::"
      jq '.[].failures // []|map(.metadata.details.name) | unique' $TEST_RESULT_FILE
    fi    
  else
    echo "Unsupported TEST_RESULT_FORMAT $TEST_RESULT_FORMAT"
    exit 1
  fi
}
