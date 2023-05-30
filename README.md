sonoff-ota-flash-cli
====================

A Bash script to perform an OTA (Over the Air) firmware update for [Sonoff DIY] device using the command line.
The script will install [Tasmota] by default - unless you tell it to install something different.

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

Either download the whole repo as a [zip file] or just download the bash script using:

```sh
curl -O https://raw.githubusercontent.com/njh/sonoff-ota-flash-cli/main/sonoff-ota-flash.sh
chmod a+rx sonoff-ota-flash.sh
```

The script uses the following commands:

* `dns-sd` (used to find the module's hostname on the network on Mac OS)
* `avahi-browse` (used to find the module's hostname on the network on Linux)
* `expect` (used on Mac OS to timeout if dns-sd doesn't find anything)
* `dscacheutil` / `getent` (used to resolve a local hostname to an IP address)
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

A final confirmation prompt is displayed before going ahead with flashing.

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
* If you give it a full URL, it will try to use that but you must either create a `.sha256` file or provide the SHA256 sum using the `-s` command-line options



Tested Operating Systems
========================

The sonoff-ota-flash.sh script has been tested with the following operating systems:

| OS                         | Working | Notes                        |
|----------------------------|---------|------------------------------|
| Mac OS 12.3.1              |   ✅    | dns-sd/1558.0.56 curl/7.79.1 |
| Raspberry Pi OS 11.3       |   ✅    | avahi-browse/0.8 curl/7.74.0 | 
| Windows 10 and possibly 11 |   ✅    | Need do the following Windows requirements** | 

**Windows 10 requirements: Need to install Windows Subsystem for Linux, then install Debian from the Windows Store, open Debian Linux command prompt and run the following commands:
sudo apt-get update
sudo apt-get install curl avahi-utils
Now you can download the bash script using the command above.
Run the command ./sonoff-ota-flash.sh with option -i to specify the device IP.

It is possible that it may work on other OS too.
If you have success on another OS, please raise a Pull Request with the details, to let other people know.


Steps to flash a Sonoff Mini module
===================================

I bought two Sonoff Mini Modules in December 2020.

They came with Firmware version 3.5.0 pre-installed on them (which uses [Protocol 2.0]).
This meant that I didn't even have to install the eWeLink software on my phone.
The OTA header on the circuit board was not populated with pins - but this doesn't matter because the unlocking can be done using software instead now.

**⚠️ Warning ⚠️** Once you flash the module with a new firmware there is no going back.
There is no way of installing eWeLink back on the module unless you have some other way of making and restoring a backup of the original firmware.

The first thing you need to do is to put the module into DIY mode.
These steps are also described on the [Sonoff DIY] page.

1. Wire up the module to mains power. The blue LED will slowly flash once every 2 seconds.
2. Hold down the button for 5 seconds. The blue LED then started flashing quickly 3 times per second.
3. I then had to hold down the button again for 5 seconds and it then flashed on and off quickly.
4. Connect to the Wifi network called ITEAD-xxxxxx using your computer. The password is `12345678`.
5. Open [http://10.10.7.1/] in your browser and enter your main Wifi network name and password. This is only used during the flashing process.
6. The module will then try and connect to your Wifi network. The blue LED will then flash twice per second. My router reported that the hostname of the device is "ESP_XXXXXX".


Once the module is in DIY mode and connected to your network, you can run the OTA flashing bash script:

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

Unfortunately, there isn't a way of knowing if flashing still in progress with this script.
But after a short while, the device should reset and start advertising a new Wifi network called something like `tasmota_62E43F-1087`.

You can then connect to the Tasmota Wifi network and configure it to use your main Wifi network.
Jump to the [Configure Wifi](https://tasmota.github.io/docs/Getting-Started/#configure-wi-fi) section
in the Tasmota Getting Started Guide for details.


License
-------

`sonoff-ota-flash.sh` is licensed under the terms of the MIT license.
See the file LICENSE for details.


Contact
-------

* Author:    Nicholas J Humfrey
* Twitter:   [@njh]



[Tasmota]:      http://www.tasmota.com/
[HomeBrew]:     https://brew.sh/
[curl]:         https://curl.se/
[zip file]:     https://github.com/njh/sonoff-ota-flash-cli/archive/main.zip
[Sonoff DIY]:   http://developers.sonoff.tech/sonoff-diy-mode-api-protocol.html
[Protocol 2.0]: https://github.com/itead/Sonoff_Devices_DIY_Tools/blob/master/SONOFF%20DIY%20MODE%20Protocol%20Doc%20v2.0%20Doc.pdf
[@njh]:         http://twitter.com/njh

[http://10.10.7.1/]: http://10.10.7.1/
