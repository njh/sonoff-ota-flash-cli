sonoff-ota-flash-cli
====================

Bash script to perform an OTA (Over the Air) firmware update for Sonoff DIY device using the command line.
The script will install Tasmota by default - unless you edit it to install something different.

Modules that support the DIY Mode Protocol v2.0 (firmware 3.5.0 or higher):
* [Basic R3](https://sonoff.tech/product/wifi-diy-smart-switches/basicr3)
* [RF R3](https://sonoff.tech/product/wifi-smart-wall-swithes/rfr3)
* [Mini](https://sonoff.tech/product/wifi-diy-smart-switches/sonoff-mini)

What this script does:

* Uses multicast DNS to find the name of the module on the local network
* Looks up the IP address for the module
* Uses the `info` endpoint to display some JSON about the module
* Uses the `ota_unlock` endpoint to unlock the module for Over The Air updates
* Uses the `ota_flash` endpoint to flash the module with Tasmota.


Requirements
============

This script uses the following commands:

* `dns-sd` (used to find the module's hostname on the network on Mac OS)
* `avahi-browse` (used to find the module's hostname on the network on Linux)
* `expect` (used on Mac OS to timeout if dns-sd doesn't find anything)
* `dscacheutil` / `getent`(used to resolve local hostname to an IP address)
* `curl` (used to make HTTP requests)

All of these should be installed on Mac OS by default.
But if you don't have [curl](https://curl.se/) on your system, then you might want to install [Homebrew](https://brew.sh/) then run:

```
brew install curl
```

On Debian / Ubuntu you may need to run:

```
sudo apt install curl avahi-utils
```


