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

awg_bin=amnezia-go-v1

atf_test_case "amnezia_kmod2go" "cleanup"
amnezia_kmod2go_head()
{
	atf_set descr 'Create a wg(4) -> amenziawg-go tunnel over an epair and pass traffic between jails'
	atf_set require.user root
}

amnezia_kmod2go_body()
{
	local pri1 pri2 pub1 pub2 wg1 wg2
	local tunnel1 tunnel2 endpoint1 endpoint2

	tunnel1=169.254.0.1
	tunnel2=169.254.0.2
	endpoint1=192.168.2.1
	endpoint2=192.168.2.2

	awg_cfg=$(awg1_config)

	setup_vnet_jails $endpoint1 $endpoint2
	setup_debug

	pri1=$(wg genkey)
	pri2=$(wg genkey)

	wg1=$(jexec wgtest1 ifconfig wg create name wg1 debug)
	atf_check -s exit:0 -o ignore -x echo "$pri1 |" \
		jexec wgtest1 awg set $wg1 listen-port 12345 private-key /dev/stdin
	pub1=$(jexec wgtest1 awg show $wg1 public-key)

	wg2=wg2
	which $awg_bin > /dev/null 2>&1 \
		|| atf_skip "This test requires $awg_bin tool and could not find it in the PATH"

	jexec wgtest2 pkill -9 $awg_bin || true
	sleep 1

	jexec wgtest2 $awg_bin --foreground $wg2 & awgpid=$!
	sleep 3

	atf_check -s exit:0 -o ignore \
		jexec wgtest2 kill -0 $awgpid

	atf_check -s exit:0 -o ignore -x "echo $pri2 |" \
		jexec wgtest2 awg set $wg2 listen-port 12345 private-key /dev/stdin
	pub2=$(jexec wgtest2 awg show $wg2 public-key)

	atf_check -s exit:0 -o ignore \
		jexec wgtest1 awg set $wg1 peer "$pub2" \
		endpoint ${endpoint2}:12345 allowed-ips ${tunnel2}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest1 awg set $wg1 $awg_cfg
	atf_check -s exit:0 \
		jexec wgtest1 ifconfig $wg1 inet ${tunnel1}/24 up debug

	atf_check -s exit:0 -o ignore \
		jexec wgtest2 awg set $wg2 peer "$pub1" \
		endpoint ${endpoint1}:12345 allowed-ips ${tunnel1}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest2 awg set $wg2 $awg_cfg
	atf_check -s exit:0 \
		jexec wgtest2 ifconfig $wg2 inet ${tunnel2}/24 up debug

	# Generous timeout since the handshake takes some time.
	atf_check -s exit:0 -o ignore jexec wgtest1 ping -c 1 -t 5 $tunnel2
	atf_check -s exit:0 -o ignore jexec wgtest2 ping -c 1 $tunnel1

	atf_check -s exit:0 kill -TERM $awgpid
	wait $awgpid
}

amnezia_kmod2go_cleanup()
{
	vnet_cleanup
}

atf_test_case "amnezia_go2kmod" "cleanup"
amnezia_go2kmod_head()
{
	atf_set descr 'Create a wg(4) <- amenziawg-go tunnel over an epair and pass traffic between jails'
	atf_set require.user root
}

amnezia_go2kmod_body()
{
	local pri1 pri2 pub1 pub2 wg1 wg2
	local tunnel1 tunnel2 endpoint1 endpoint2

	tunnel1=169.254.0.1
	tunnel2=169.254.0.2
	endpoint1=192.168.2.1
	endpoint2=192.168.2.2

	awg_cfg=$(awg1_config)

	setup_vnet_jails $endpoint1 $endpoint2
	setup_debug

	pri1=$(wg genkey)
	pri2=$(wg genkey)

	wg1=$(jexec wgtest1 ifconfig wg create name wg1 debug)
	atf_check -s exit:0 -o ignore -x echo "$pri1 |" \
		jexec wgtest1 awg set $wg1 listen-port 12345 private-key /dev/stdin
	pub1=$(jexec wgtest1 awg show $wg1 public-key)

	wg2=wg2
	which $awg_bin > /dev/null 2>&1 \
		|| atf_skip "This test requires $awg_bin tool and could not find it in the PATH"

	jexec wgtest2 pkill -9 $awg_bin || true
	sleep 1

	jexec wgtest2 amnezia-go --foreground $wg2 & awgpid=$!
	sleep 3

	atf_check -s exit:0 -o ignore \
		jexec wgtest2 kill -0 $awgpid

	atf_check -s exit:0 -o ignore -x "echo $pri2 |" \
		jexec wgtest2 awg set $wg2 listen-port 12345 private-key /dev/stdin
	pub2=$(jexec wgtest2 awg show $wg2 public-key)

	atf_check -s exit:0 -o ignore \
		jexec wgtest1 awg set $wg1 peer "$pub2" \
		endpoint ${endpoint2}:12345 allowed-ips ${tunnel2}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest1 awg set $wg1 $awg_cfg
	atf_check -s exit:0 \
		jexec wgtest1 ifconfig $wg1 inet ${tunnel1}/24 up debug

	atf_check -s exit:0 -o ignore \
		jexec wgtest2 awg set $wg2 peer "$pub1" \
		endpoint ${endpoint1}:12345 allowed-ips ${tunnel1}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest2 awg set $wg2 $awg_cfg
	atf_check -s exit:0 \
		jexec wgtest2 ifconfig $wg2 inet ${tunnel2}/24 up debug

	# Generous timeout since the handshake takes some time.
	atf_check -s exit:0 -o ignore jexec wgtest2 ping -c 1 -t 5 $tunnel1
	atf_check -s exit:0 -o ignore jexec wgtest1 ping -c 1 $tunnel2

	atf_check -s exit:0 kill -TERM $awgpid
	wait $awgpid
}

amnezia_go2kmod_cleanup()
{
	vnet_cleanup
}

atf_init_test_cases()
{
	atf_add_test_case "amnezia_kmod2go"
	atf_add_test_case "amnezia_go2kmod"
}
