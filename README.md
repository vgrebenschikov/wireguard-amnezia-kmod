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

git clone https://github.com/vgrebenschikov/wireguard-freebsd.git
make -C wireguard-freebsd
sudo make -C wireguard-freebsd install

If you'd prefer to build this repo from scratch, rather than using a package, first make sure you have the latest net/wireguard-tools package
installed.

```
# git clone https://git.zx2c4.com/wireguard-freebsd
# make -C wireguard-freebsd/src
# make -C wireguard-freebsd/src load install
```

After that, it should be possible to use `wg(8)` and `wg-quick(8)` like usual, but with the faster kernel implementation.
