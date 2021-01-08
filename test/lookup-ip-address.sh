#!/usr/bin/env bash

# shellcheck source=sonoff-ota-flash.sh
source "${BASH_SOURCE%/*}/../sonoff-ota-flash.sh"

set +e
set +u

testLookupLocalhost() {
  assertEquals '127.0.0.1' $(lookup_ip_address localhost)
}

testLookupRootNameserver() {
  assertEquals '198.41.0.4' $(lookup_ip_address a.root-servers.net.)
}

# shellcheck disable=SC1091
source "$(command -v shunit2)"
