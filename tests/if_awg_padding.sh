#!/usr/libexec/atf-sh
#
# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2021 The FreeBSD Foundation
#
# This software was developed by Mark Johnston under sponsorship
# from the FreeBSD Foundation.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

. "$(atf_get_srcdir)/vnet.subr"
. "$(atf_get_srcdir)/awg.subr"

atf_test_case "padding_mtu" "cleanup"
padding_mtu_head()
{
	atf_set descr "Bound randomized AWG transport padding by the peer window"
	atf_set require.user root
	atf_set require.progs "awg tcpdump"
}

padding_mtu_body()
{
	local epair wg1 wg2 pub1 pub2 capture i
	local pri1 pri2 header_key
	local endpoint1=192.0.2.1 endpoint2=192.0.2.2
	local tunnel1=198.51.100.1 tunnel2=198.51.100.2

	kldload -n if_wg || atf_skip "This test requires if_wg"
	vnet_init
	epair=$(vnet_mkepair)
	vnet_mkjail wgtest1 ${epair}a
	vnet_mkjail wgtest2 ${epair}b
	atf_check jexec wgtest1 ifconfig ${epair}a inet "$endpoint1/24" mtu 1500 up
	atf_check jexec wgtest2 ifconfig ${epair}b inet "$endpoint2/24" mtu 1500 up

	pri1=$(awg genkey) || atf_fail "Could not generate first key"
	pri2=$(awg genkey) || atf_fail "Could not generate second key"
	header_key=$(awg genkey) || atf_fail "Could not generate header key"
	wg1=$(jexec wgtest1 ifconfig wg create)
	wg2=$(jexec wgtest2 ifconfig wg create)
	printf '%s\n' "$pri1" | jexec wgtest1 awg set "$wg1" \
	    listen-port 12345 private-key /dev/stdin ||
	    atf_fail "Could not set first private key"
	printf '%s\n' "$pri2" | jexec wgtest2 awg set "$wg2" \
	    listen-port 12345 private-key /dev/stdin ||
	    atf_fail "Could not set second private key"
	pub1=$(jexec wgtest1 awg show "$wg1" public-key)
	pub2=$(jexec wgtest2 awg show "$wg2" public-key)
	printf '%s\n' "$header_key" | jexec wgtest1 awg set "$wg1" \
	    s1 25 s2 25 s3 25 s4 25 content-padding-addition 14-49 \
	    random-trailers on header-protection-key /dev/stdin peer "$pub2" \
	    endpoint "$endpoint2:12345" allowed-ips "$tunnel2/32" ||
	    atf_fail "Could not configure first peer"
	printf '%s\n' "$header_key" | jexec wgtest2 awg set "$wg2" \
	    s1 25 s2 25 s3 25 s4 25 content-padding-addition 14-49 \
	    random-trailers on header-protection-key /dev/stdin peer "$pub1" \
	    endpoint "$endpoint1:12345" allowed-ips "$tunnel1/32" ||
	    atf_fail "Could not configure second peer"
	atf_check jexec wgtest1 ifconfig "$wg1" inet "$tunnel1/24" mtu 1408 up
	atf_check jexec wgtest2 ifconfig "$wg2" inet "$tunnel2/24" mtu 1408 up

	# Prime the window with 1408 inner bytes plus 85 bytes of IPv4
	# encapsulation overhead. The smaller probes leave 32 bytes for padding.
	atf_check -o ignore jexec wgtest1 ping -n -D -c 1 -t 5 -s 1380 "$tunnel2"

	jexec wgtest1 tcpdump -l -nn -s 96 -i ${epair}a \
	    "ip and src host $endpoint1 and dst host $endpoint2 and
	    ((udp dst port 12345 and ip[2:2] > 1493) or
	    (ip[6:2] & 0x3fff != 0))" > oversized 2> capture.log &
	capture=$!
	echo "$capture" > capture.pid
	for i in $(jot 20); do
		grep -q "listening on" capture.log && break
		sleep 0.1
	done
	grep -q "listening on" capture.log || atf_fail "tcpdump did not start"

	atf_check -o ignore jexec wgtest1 ping -n -D -c 64 -i 0.03 -t 8 -s 1348 "$tunnel2"
	kill -INT "$capture"
	wait "$capture" || :
	rm -f capture.pid
	atf_check -o match:"^0 packets dropped by kernel$" cat capture.log
	atf_check -s exit:1 -o empty grep -E . oversized
}

padding_mtu_cleanup()
{
	if [ -f capture.pid ]; then
		kill -INT "$(cat capture.pid)" 2>/dev/null || :
	fi
	vnet_cleanup
	awg_test_cleanup
}

atf_init_test_cases()
{
	atf_add_test_case "padding_mtu"
}
