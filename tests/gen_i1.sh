#!/bin/sh

# Requires:
# pkg install quiche wireshark-nox11
#

(tshark -f udp -Y quic -T fields -e udp.payload | perl -p -e 'chomp; s/0*$//; print "<b 0x$_>\n"; exit;') &
tsharkpid=$!

sleep 1

quiche-client https://www.cloudflare.com/ > /dev/null 2>&1
# curl -o /dev/null--http3 https://www.cloudflare.com/

wait $tsharkpid