# Amnezia WireGuard for FreeBSD

This is a kernel module for FreeBSD to support [WireGuard](https://www.wireguard.com/). 
It is being based on in-tree module implementation of if_wg.

but adding basic support for [AmneziaWG](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) -
sending junk packets before handshake.

Onlu partial Implemenation - only Jc, Jmin, Jmax options are supported

### Installation instructions

From port: [net/wireguard-amnezia](https://github.com/vgrebenschikov/wireguard-amnezia-kmod-port)

### Building instructions

If you'd prefer to build this repo from scratch, rather than using a package
installed.

```
git clone https://github.com/vgrebenschikov/wireguard-amnezia-kmod
make -C wireguard-amnezia-kmod
sudo make -C wireguard-amnezia-kmod install
```

After that, it should be possible to use `wg(8)` and `wg-quick(8)` like usual, but with the faster kernel implementation. 
