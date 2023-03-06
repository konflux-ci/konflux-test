#!/usr/bin/env bash

# Copyright 2023.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

RESULTS_FILE=${1-}

if [ -z "${RESULTS_FILE}" ]; then
    echo "Please provide path to file to be tested" >&2
    exit 2
fi

EXPECTED_LINES="----------- SCAN SUMMARY -----------
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
    if ! grep -- "${line}" "${RESULTS_FILE}"; then
        echo "Expected pattern not found: \"${line}\"" >&2
        exit 1
    fi
done <<< "${EXPECTED_LINES}"

echo "Test Passed \o/" >&2