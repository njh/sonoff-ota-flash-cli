#!/usr/bin/env bash

# shellcheck source=sonoff-ota-flash.sh
source "${BASH_SOURCE%/*}/../sonoff-ota-flash.sh"

set +e
set +u

testPrettyPrintSimple() {
  input=$'{"foo": 1,"bar": 2}'
  assertEquals $' {\n    "foo": 1,\n    "bar": 2\n }' "$(echo "${input}" | json_pretty_print)"
}

# shellcheck disable=SC1091
source "$(command -v shunit2)"
