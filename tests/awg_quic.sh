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

atf_test_case "awg_quic" "cleanup"
awg_quic_head()
{
	atf_set descr 'Create a wg(4) tunnel over an epair and pass traffic between jails'
	atf_set require.user root
}

awg_quic_body()
{
	local pri1 pri2 pub1 pub2 wg1 wg2
	local endpoint1 endpoint2 tunnel1 tunnel2

	pri1=$(wg genkey)
	pri2=$(wg genkey)

	tunnel1=169.254.0.1
	tunnel2=169.254.0.2
	endpoint1=192.168.2.1
	endpoint2=192.168.2.2

	setup_debug
	which tshark > /dev/null 2>&1 || atf_skip "This test requires tshark and could not find"

	setup_vnet_jails $endpoint1 $endpoint2

	awg_cfg=$(awg_config)

	wg1=$(jexec wgtest1 ifconfig wg create debug name wg1)
	atf_check -s exit:0 -o ignore -x "echo $pri1 |" \
		jexec wgtest1 wg set $wg1 listen-port 12345 private-key /dev/stdin
	pub1=$(jexec wgtest1 wg show $wg1 public-key)

	wg2=$(jexec wgtest2 ifconfig wg create name wg2 debug)
	atf_check -s exit:0 -o ignore -x "echo $pri2 |" \
		jexec wgtest2 wg set $wg2 listen-port 12345 private-key /dev/stdin
	pub2=$(jexec wgtest2 wg show $wg2 public-key)

	atf_check -s exit:0 -o ignore \
		jexec wgtest1 wg set $wg1 peer "$pub2" \
		endpoint ${endpoint2}:12345 allowed-ips ${tunnel2}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest1 awg set $wg1 $awg_cfg
	atf_check -s exit:0 -o ignore \
		jexec wgtest1 awg set $wg1 i1 "$(agw_long_i)"
	atf_check -s exit:0 \
		jexec wgtest1 ifconfig $wg1 inet ${tunnel1}/24 up

	atf_check -s exit:0 -o ignore \
		jexec wgtest2 wg set $wg2 peer "$pub1" \
		endpoint ${endpoint1}:12345 allowed-ips ${tunnel1}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest2 awg set $wg2 $awg_cfg
	atf_check -s exit:0 \
		jexec wgtest2 ifconfig $wg2 inet ${tunnel2}/24 up

	atf_check -s exit:0 -o match:QUIC -e ignore \
		tshark -i wgbr0 -f udp -l -c10 \
			-Y quic \
			-T fields \
			-e frame.number \
			-e frame.time_relative \
			-e ip.src \
			-e ip.dst \
			-e _ws.col.Protocol \
			-e frame.len \
			-e _ws.col.Info &
	tsharkpid=$!

	atf_check -s exit:0 -o ignore sleep 3

	# Generous timeout since the handshake takes some time.
	atf_check -s exit:0 -o ignore jexec wgtest1 ping -c 1 -t 5 $tunnel2
	atf_check -s exit:0 -o ignore jexec wgtest2 ping -c 15 $tunnel1

	wait $tsharkpid

}

awg_quic_cleanup()
{
	vnet_cleanup
	rm -f quic.txt
}

atf_init_test_cases()
{
	atf_add_test_case "awg_quic"
}
