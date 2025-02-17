#!/bin/bash
#
# BASH Shell script to flash a Sonoff DIY module Over The Air.
# 

FIRMWARE_URL_BASE="http://sonoff-ota.aelius.com/"
DEFAULT_FILENAME="tasmota-latest-lite.bin"
IPADDRESS=
SHASUM=

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
  local url="http://${hostname}:8081/zeroconf/${path}"

  if [ -z "${body}" ]; then
    body='{"data":{}}'
  fi

  # Build up the curl command arguments as an array
  cmd=('curl' '--silent' '--show-error')
  cmd+=('-XPOST')
  cmd+=('--header' "Content-Type: application/json")
  cmd+=('--data-raw' "${body}")
  cmd+=("${url}")

  output=$("${cmd[@]}")
  exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    echo "Error posting to: ${url}"
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

mdns_browse() {
  local service="${1}"
  local domain="${2:local.}"
  if command -v dns-sd &> /dev/null; then
    # Use the 'dns-sd' command on Mac OS
    # expect is used because dns-sd doesn't timeout
    output=$(expect <<-EOD
			set timeout 10
			spawn -noecho dns-sd -B ${service} ${domain}
			expect {
			  "  Add  " {exit 0}
			  timeout   {exit 1}
			  eof       {exit 2}
			  default   {exp_continue}
			}
		EOD
    )
    # Find the first 'Add' line from the output
    echo "${output}" | grep -m 1 '  Add  ' | awk '{sub("\r", "", $NF); print $NF}'
  elif command -v avahi-browse &> /dev/null; then
    # Use the 'avahi-browse' command on Linux
    avahi-browse -pt -d "${domain}" "${service}" | awk 'BEGIN {FS=";"} {if ($1=="+" && $3=="IPv4") print $4}'
  else
    echo "Unable to perform multicast DNS discovery : didn't find dns-sd or avahi-browse." >&2
    exit 1
  fi
}

discover_module() {
  echo "Searching for Sonoff module on network..."
  hostname=$(mdns_browse '_ewelink._tcp')
  if [ -z "${hostname}" ]; then
    echo "Failed to find a Sonoff module on the local network." >&2
    exit 2
  else
    echo "Found module on network."
    echo "Hostname: ${hostname}"
  fi

  # Now get the IP address for the hostname
  IPADDRESS=$(lookup_ip_address "${hostname}.local.")
  if [ -z "${IPADDRESS}" ]; then
    echo "Failed to resolve IP address for ${hostname}" >&2
    exit 3
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
    echo "Requesting OTA flashing..."
    sonoff_http_request "${IPADDRESS}" ota_flash "{\"data\":{\"downloadUrl\":\"${FIRMWARE_URL}\",\"sha256sum\":\"${SHASUM}\"}}"
    echo
  else
    echo "Aborting"
    exit 1
  fi
}

check_firmware_exists() {
  echo "Checking new firmware file exists"
  output=$(curl '--fail' '--silent' '--show-error' '--head' "${FIRMWARE_URL}")
  exit_code=$?
  if [ "$exit_code" -ne 0 ]; then
    if [ "$exit_code" -eq 22 ]; then
      echo "The firmware file does not exist: ${FIRMWARE_URL}" >&2
    else
      echo "There was an error checking if firmware exists: ${FIRMWARE_URL}" >&2
    fi
    exit $exit_code
  else
    echo "OK"
    echo
  fi
}

lookup_shasum() {
  echo "Looking up sha256sum for firmware"
  output=$(curl '--fail' '--silent' '--show-error' "${FIRMWARE_URL}.sha256")
  exit_code=$?
  if [ "$exit_code" -ne 0 ]; then
    echo "Failed to get .sha256 file for: ${FIRMWARE_URL}" >&2
    echo "Please add a .sha256 file to server, or pass the SHA256 on the command line" >&2
    exit $exit_code
  fi

  # Check it looks like it is in the right format
  if [[ $output =~ ^([0-9a-f]{64})\ \*(.+)$ ]]; then
    SHASUM="${BASH_REMATCH[1]}"
    echo "OK"
    echo
  else
    echo "Failed to parse SHA256 sum from file: ${output}" >&2
    exit 2
  fi
}

display_help() {
  printf "Usage: %s [options] [<filename or url>]\n" "${0}"
  printf "If just a filename is given, it is relative to %s\n\n" "${FIRMWARE_URL_BASE}"
  printf -- "Options:\n"
  grep -E -e '^[[:space:]]*# PARAM_Usage:' -e '^[[:space:]]*# PARAM_Description:' "${0}" | while read -r usage; read -r description; do
    if [[ ! "${usage}" =~ Usage ]] || [[ ! "${description}" =~ Description ]]; then
      _exiterr "Error generating help text."
    fi
    printf " %-32s %s\n" "${usage##"# PARAM_Usage: "}" "${description##"# PARAM_Description: "}"
  done

  exit 1
}


parse_options() {
  check_parameters() {
    if [[ -z "${1:-}" ]]; then
      echo "The specified command requires additional parameters. See help:" >&2
      display_help >&2
      exit 1
    elif [[ "${1:0:1}" = "-" ]]; then
      _exiterr "Invalid argument: ${1}"
    fi
  }

  local params=()
  while (( "$#" )); do
    case "$1" in
      # PARAM_Usage: -i, --ipaddress <ipaddress>
      # PARAM_Description: Specify the IP address of the Sonoff module
      -i|--ipaddress)
        shift 1
        check_parameters "${1:-}"
        IPADDRESS="${1}"
        ;;
      # PARAM_Usage: -s, --sha256 <sha256>
      # PARAM_Description: Specify the SHA256 sum of the firmware
      -s|--sha256)
        shift 1
        check_parameters "${1:-}"
        SHASUM="${1}"
        ;;
      # PARAM_Usage: -h, --help
      # PARAM_Description: Display this message
      -h|--help)
        display_help
        ;;
      -*)
        echo "Error: Unsupported flag $1" >&2
        display_help
        ;;
      *) # preserve positional arguments
        if [ -n "$1" ]; then
          params+=("$1")
        fi
        ;;
    esac
    shift
  done

  if [ "${#params[@]}" -eq 0 ]; then
    FIRMWARE_URL="${DEFAULT_FILENAME}"
  elif [ "${#params[@]}" -eq 1 ]; then
    FIRMWARE_URL="${params[0]}"
  else
    display_help
  fi

  # If the filename doesn't start http: then prepend the base URL  
  if [[ ! ${FIRMWARE_URL} =~ ^https?: ]]; then
    FIRMWARE_URL="${FIRMWARE_URL_BASE}${FIRMWARE_URL}"
  fi
}

main() {
  parse_options "${@:-}"

  check_firmware_exists

  if [ -z "${SHASUM:-}" ]; then
    lookup_shasum
  fi

  if [ -z "${IPADDRESS:-}" ]; then
    discover_module
  fi

  display_info

  ota_unlock

  ota_flash
  
  echo "Please wait for your device to finish flashing."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  main "${@:-}"
fi
