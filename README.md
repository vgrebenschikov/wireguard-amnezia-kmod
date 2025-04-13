# WireGuard for FreeBSD

This is a kernel module for FreeBSD to support [WireGuard](https://www.wireguard.com/). It is being developed here before its eventual submission to FreeBSD.

This version is originaly based on FreeBSD in-tree driver, 
but adding basic support for [AmneziaWG](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) -
sending junk packets before handshake.

### Installation instructions

Snapshots of this may be installed from packages:

```
# pkg install wireguard-amnezia
```

### Building instructions

If you'd prefer to build this repo from scratch, rather than using a package
installed.

```
git clone https://github.com/vgrebenschikov/wireguard-amnezia.git
make -C wireguard-freebsd
sudo make -C wireguard-freebsd install
```

After that, it should be possible to use `wg(8)` and `wg-quick(8)` like usual, but with the faster kernel implementation.
