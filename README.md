# Amnezia WireGuard for FreeBSD kernel driver

This is a kernel module for FreeBSD to support [WireGuard](https://www.wireguard.com/). 
It is derived from the in-tree module implementation of if_wg, adding support for
[AmneziaWG](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) to
hide Wireguard protocol from DPI detectors.

## Installation instructions

From ports:

- [net/wireguard-amnezia-kmod](https://github.com/vgrebenschikov/wireguard-amnezia-kmod-port)
- [net/amneziawg-tools](https://github.com/vgrebenschikov/amneziawg-tools)

## Building instructions

If you'd prefer to build this repo from scratch, rather than using a package
installed.

```shell
git clone https://github.com/vgrebenschikov/wireguard-amnezia-kmod
make -C wireguard-amnezia-kmod
sudo make -C wireguard-amnezia-kmod install
```

Make sure that the module is loaded from the correct location (/boot/modules/if_wg.ko) and not from the standard kernel modules directory.

After that, it should be possible to use `wg(8)` and `wg-quick(8)` like usual, but with the faster kernel implementation.
Please use the [AmneziaWG](https://github.com/amnezia-vpn/amneziawg-tools) version of these tools as it supports the additional Amnezia-specific parameters.
