# AmneziaWG FreeBSD kernel driver

AmneziaWG is a contemporary version of the popular VPN protocol, WireGuard.
It offers protection against detection by Deep Packet Inspection (DPI) systems.
At the same time, it retains the simplified architecture and high performance
of the original.

The progenitor of AmneziaWG, WireGuard, is known for its efficiency, but
it does have issues with detection due to distinctive packet signatures.
AmneziaWG addresses this problem by employing advanced obfuscation methods,
allowing its traffic to blend seamlessly with regular internet traffic.
As a result, AmneziaWG maintains high performance while adding an extra layer
of stealth, making it a superb choice for those seeking a fast and discreet
VPN connection.

This is a kernel module for FreeBSD to support [WireGuard](https://www.wireguard.com/).
It is derived from the in-tree module implementation of if_wg, adding support for
[AmneziaWG](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) to
hide Wireguard protocol from DPI detectors.

In this repository native FreeBSD if_wg driver with minimum changes to get AmneziaWG functionality.
To compare within FreeBSD tree one may use [compare](https://github.com/vgrebenschikov/freebsd-src/compare/main...feature/awg?expand=1)

## Building instructions

Building and installing driver

```shell
git clone https://github.com/vgrebenschikov/wireguard-amnezia-kmod
make -C wireguard-amnezia-kmod
sudo make -C wireguard-amnezia-kmod install
```

Make sure that the module is loaded from the correct location (/boot/modules/if_wg.ko) and not from the standard kernel modules directory.

After that, it should be possible to use `awg(8)` and `awg-quick(8)` like usual, but with the faster kernel implementation.
Please use the [AmneziaWG](https://github.com/amnezia-vpn/amneziawg-tools) version of these tools as it supports the additional Amnezia-specific parameters.

## Installation from ports

If you wish to use ports to install driver:

- [net/amneziawg-kmod](https://github.com/vgrebenschikov/amneziawg-kmod)
- [net/amneziawg-tools](https://github.com/vgrebenschikov/amneziawg-tools)

Also, please note that kmod port will also rename the driver to if_awg.ko to avoid conflict.
