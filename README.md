sonoff-ota-flash-cli
====================

Bash script to perform an Over the Air firmware update for Sonoff DIY device on Mac command line.
The script will install Tasmota by default - unless you edit it to install something different.

What this script does:

* Uses multicast DNS to find the name of the module on the local network
* Looks up the IP address for the module
* Uses the `info` endpoint to display some JSON about the module
* Uses the `ota_unlock` endpoint to unlock the module for Over The Air updates
* Uses the `ota_flash` endpoint to flash the module with Tasmota.


Requirements
============

This script uses the following commands:

* `dns-sd` (used to find the module's hostname on the network)
* `expect` (used to timeout if dns-sd doesn't find anything)
* `dscacheutil` (used to resolve local hostname to an IP address)
* `curl` (used to make HTTP requests)

All of these should be installed on Mac OS by default.

It will not run on Linux because:

- `dns-sd` is not available on Linux (and `avahi-browse` is not available on Mac)
- `dscacheutil` is not available on Linux (and `getent` is not available on Mac)

