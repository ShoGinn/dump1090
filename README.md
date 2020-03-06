# dump1090

Docker container for ADS-B - This is the flightaware dump1090 component

This is part of a suite of applications that can be used to feed ADSB data with compatible devices including:

* Any RTLSDR USB device
* Any network AVR or BEAST device
* Any serial AVR or BEAST device

## Container Requirements

This is a multi architecture build that supports arm (armhf/arm64) and amd64

## Container Setup

Ensure you pass your USB device path.

Also make sure you add the nice capability to your ```docker run```

```--cap-add=SYS_NICE```

Otherwise you will get errors (this helps it play nice ;) )

### Defaults

* Port 30002/tcp is used for raw output and is exposed by default
* Port 30005/tcp is for Beast output

### User Configured

* No user configurable options

#### Example docker run

```bash
docker run -d \
--restart unless-stopped \
--name='dump1090' \
--cap-add=SYS_NICE \
--device=/dev/bus/usb \
shoginn/dump1090:latest

```

## Status

| branch | Status |
|--------|--------|
| master | [![Build Status](https://travis-ci.org/ShoGinn/dump1090.svg?branch=master)](https://travis-ci.org/ShoGinn/dump1090) |
