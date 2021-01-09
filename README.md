sonoff-ota-flash-cli
====================

A Bash script to perform an OTA (Over the Air) firmware update for [Sonoff DIY] device using the command line. The script will install [Tasmota] by default - unless you tell it to install something different.

Modules that support the DIY Mode Protocol v2.0 (firmware 3.5.0 or higher):
* [Sonoff Basic R3](https://sonoff.tech/product/wifi-diy-smart-switches/basicr3)
* [Sonoff RF R3](https://sonoff.tech/product/wifi-smart-wall-swithes/rfr3)
* [Sonoff Mini](https://sonoff.tech/product/wifi-diy-smart-switches/sonoff-mini)

What this script does:

* Uses multicast DNS to find the name of the module on the local network
* Looks up the IP address for the module
* Uses the `info` endpoint to display some JSON about the module
* Uses the `ota_unlock` endpoint to unlock the module for Over The Air updates
* Uses the `ota_flash` endpoint to flash the module with Tasmota.


Installation
============

Either download the whole repo as [zip file], or just download the bash script using:

```sh
curl -O https://raw.githubusercontent.com/njh/sonoff-ota-flash-cli/main/sonoff-ota-flash.sh
chmod a+rx sonoff-ota-flash.sh
```

The script uses the following commands:

* `dns-sd` (used to find the module's hostname on the network on Mac OS)
* `avahi-browse` (used to find the module's hostname on the network on Linux)
* `expect` (used on Mac OS to timeout if dns-sd doesn't find anything)
* `dscacheutil` / `getent`(used to resolve local hostname to an IP address)
* `curl` (used to make HTTP requests)

All of these should be installed on Mac OS by default.
But if you don't have [curl] on your system, then you might want to install [Homebrew] then run:

```sh
brew install curl
```

On Debian / Ubuntu you may need to install the dependencies using:

```sh
sudo apt install curl avahi-utils
```


Usage
=====

Given no parameters, this script will find a Sonoff module (in DIY mode) on your network and flash it with the latest version of [Tasmota].

A final-confirmation prompt is displayed before going ahead with flashing.

```sh
Usage: ./sonoff-ota-flash.sh [options] [<filename or url>]
If just a filename is given, it is relative to http://sonoff-ota.aelius.com/

Options:
 -i, --ipaddress <ipaddress>      Specify the IP address of the Sonoff module
 -s, --sha256 <sha256>            Specify the SHA256 sum of the firmware
 -h, --help                       Display this message
```

Options:

* If you have more than one module, or auto-discovery isn't working you can use `-i` to specify the IP address of the module to flash
* If you give it a filename, it will try and use that file from http://sonoff-ota.aelius.com/
* If you give it a full URL, it will try use that but you must either create a `.sha256` file or provide the SHA256 sum using the `-s` command line options


Example run
-----------

First follow the steps to put the device into DIY mode and connected to your local network:
http://developers.sonoff.tech/sonoff-diy-mode-api-protocol.html

Then run the bash script:

```
$ ./sonoff-ota-flash.sh 
Checking new firmware file exists
OK

Looking up sha256sum for firmware
OK

Searching for Sonoff module on network...
Found module on network.
Hostname: eWeLink_1000e4c17c
IPv4 Address: 192.168.1.104

Getting Module Info...
 {
    "seq":2,
    "error":0,
    "data":
    {
        "switch":"off",
        "startup":"off",
        "pulse":"off",
        "pulseWidth":500,
        "ssid":"test",
        "otaUnlock":false,
        "fwVersion":"3.5.0",
        "deviceid":"1000e4c17c",
        "bssid":"b4:fb:de:ad:be:ef",
        "signalStrength":-52
    }
 }

Unlocking for OTA flashing...
 {
    "seq":2,
    "error":0
 }

Proceed with flashing? [N/y] y
Requesting OTA flashing...
 {
    "seq":3,
    "error":0
 }

Please wait for your device to finish flashing.
```

Unfortunately there isn't a way of knowing if flashing still in progress with this script.
But after a short while the device should reset and start advertising a new Wifi network called something like `tasmota_62E43F-1087`.


License
-------

`sonoff-ota-flash.sh` is licensed under the terms of the MIT license.
See the file LICENSE for details.


Contact
-------

* Author:    Nicholas J Humfrey
* Twitter:   [@njh]



[Tasmota]:     https://tasmota.github.io/
[HomeBrew]:    https://brew.sh/
[curl]:        https://curl.se/
[zip file]:    https://github.com/njh/sonoff-ota-flash-cli/archive/main.zip
[Sonoff DIY]:  http://developers.sonoff.tech/sonoff-diy-mode-api-protocol.html
[@njh]:        http://twitter.com/njh
