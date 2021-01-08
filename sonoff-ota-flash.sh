#!/bin/bash
#
# BASH Shell script to flash a Sonoff DIY module Over The Air.
# 
# Uses the 'dns-sd' command, which is only available on Mac OS.
#

BIN_URL="http://sonoff-ota.aelius.com/tasmota-9.2.0-lite.bin"
SHASUM="c61dd7448ce5023ca5ca8997833fd240829c902fa846bafca281f01c0c5b4d29"


# JSON Pretty Print by Evgeny Karpov
# https://stackoverflow.com/a/38607019/1156096
json_pretty_print() {
  grep -Eo '"[^"]*" *(: *([0-9]*|"[^"]*")[^{}\["]*|,)?|[^"\]\[\}\{]*|\{|\},?|\[|\],?|[0-9 ]*,?' | \
  awk '{if ($0 ~ /^[}\]]/ ) offset-=4; printf "%*c%s\n", offset, " ", $0; if ($0 ~ /^[{\[]/) offset+=4}'
}

sonoff_http_request() {
  local hostname="${1}"
  local path="${2}"
  local body="${3:-}"

  if [ -z "${body}" ]; then
    body='{"deviceid":"","data":{}}'
  fi

  # Build up the curl command arguments as an array
  cmd=('curl' '--silent' '--show-error')
  cmd+=('-XPOST')
  cmd+=('--header' "Content-Type: application/json")
  cmd+=('--data-raw' "${body}")
  cmd+=("http://${hostname}:8081/zeroconf/${path}")

  output=$("${cmd[@]}")
  exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    echo "${output}"
    exit $exit_code
  fi

  echo "${output}" | json_pretty_print
  sleep 1
}


lookup_ip_address() {
  local hostname="${1}"
  # We use dscacheutil / getent because it can do multicast dns lookups
  if command -v dscacheutil &> /dev/null; then
    dscacheutil -q host -a name "${hostname}" | grep -m 1 'ip_address:' | awk '{print $2}'
  elif command -v getent &> /dev/null; then
    getent ahostsv4 "${hostname}" | grep -m 1 -oE "^([0-9]{1,3}\.){3}[0-9]{1,3}"
  else
    echo "Unable to resolve hostname to ip address: didn't find dscacheutil or getent." >&2
    exit 1
  fi
}

discover_module() {
  echo "Searching for Sonoff module on network..."
  output=$(expect <<-EOD
		set timeout 10
		spawn -noecho dns-sd -B _ewelink._tcp local.
		expect {
		  "  Add  " {exit 0}
		  timeout   {exit 1}
		  eof       {exit 2}
		  default   {exp_continue}
		}
	EOD
  )

  # Get the first 'Add' line from the output
  line=$(echo "${output}" | grep -m 1 '  Add  ')
  if [ -z "${line}" ]; then
    echo "Failed to find a Sonoff module on the local network." >&2
    exit 2
  fi

  echo "Found module on network."
  hostname=$(echo "${line}" | awk '{sub("\r", "", $NF) ; print $NF}')".local."
  echo "Hostname: ${hostname}"

  # Now get the IP address for the hostname
  IPADDRESS=$(lookup_ip_address "${hostname}")
  if [ -z "${IPADDRESS}" ]; then
    echo "Failed to resolve IP address for ${hostname}" >&2
    exit 2
  fi
  echo "IPv4 Address: ${IPADDRESS}"
  echo
}
  
display_info() {
  echo "Getting Module Info..."
  sonoff_http_request "${IPADDRESS}" info
  echo
}

ota_unlock() {
  echo "Unlocking for OTA flashing..."
  # FIXME: skip this if already unlocked
  sonoff_http_request "${IPADDRESS}" ota_unlock
  echo
}

ota_flash() {
  read -p "Proceed with flashing? [N/y] " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    echo "Flashing..."
    sonoff_http_request "${IPADDRESS}" ota_flash "{\"deviceid\":\"\",\"data\":{\"downloadUrl\":\"${BIN_URL}\",\"sha256sum\":\"${SHASUM}\"}}"
    echo
  else
    echo "Aborting"
    exit 1
  fi
}

main() {
  discover_module

  display_info

  ota_unlock

  ota_flash
  
  echo "Done."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  main "${@:-}"
fi
