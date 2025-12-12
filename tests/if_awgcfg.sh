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

atf_test_case "awg_configuration" "cleanup"
awg_configuration_head()
{
	atf_set descr 'Create a awg(4) and test parameter constraints'
	atf_set require.user root
}

awg_configuration_body()
{
	local epair pri1 pri2 pub1 pub2 wg1 wg2
		local endpoint1 endpoint2 tunnel1 tunnel2

	kldload -n if_wg || atf_skip "This test requires if_wg and could not load it"

	wg=$(ifconfig wg create debug)
	awgcfg=$(awg_config)

	setup_debug

	for p in jc jmin jmax s1 s2 s3 s4 h1 h2 h3 h4; do
		val=$(awg_config_get $p $awgcfg)

		echo "==[ $p = $val ]==================="

		# set
		atf_check -s exit:0 -o ignore			awg set $wg $p $val
		atf_check -s exit:0 -o match:"$val"		awg show $wg $p
		atf_check -s exit:0 -o match:"$p: $val"	awg show $wg
		echo

		echo "==[ $p - <reset> ]==================="

		# reset
		atf_check -s exit:0 -o ignore			awg set $wg $p 0
		atf_check -s exit:0 -o match:"0"		awg show $wg $p
		atf_check -s exit:0 -o not-match:"$p: "	awg show $wg
		echo
	done

	for p in i1 i2 i3 i4 i5; do
		n1=$(jot -r 1 1 100)
		n2=$(jot -r 1 1 100)
		n3=$(jot -r 1 1 100)
		val="<b 0xdeadbeef><c><b 0xdeadbeef><t><r $n1><rd $n2><c><rc $n3>"

		echo "==[ $p = $val ]==================="
		atf_check -s exit:0 -o ignore			awg set $wg $p "$val"
		atf_check -s exit:0 -o match:"$val"		awg show $wg $p
		atf_check -s exit:0 -o match:"$p: $val"	awg show $wg
		echo

		val="$(agw_long_i)"
		echo "==[ $p = <long> ]==================="
		atf_check -s exit:0 -o ignore			awg set $wg $p "$val"
		atf_check -s exit:0 -o match:"$val"		awg show $wg $p
		atf_check -s exit:0 -o match:"$p: $val"	awg show $wg
		echo

		echo "==[ $p - <reset> ]==================="

		# reset
		atf_check -s exit:0 -o ignore			awg set $wg $p ''
		atf_check -s exit:0 -o match:"^$"		awg show $wg $p
		atf_check -s exit:0 -o not-match:"$p: "	awg show $wg

		echo

	done
}

awg_configuration_cleanup()
{
	for i in $(ifconfig -g wg); do
		ifconfig $i destroy
	done
}

atf_test_case "awg_constraints" "cleanup"
awg_constraints_head()
{
	atf_set descr 'Create a awg(4) and test parameter constraints'
	atf_set require.user root
}

awg_constraints_body()
{
	local epair pri1 pri2 pub1 pub2 wg1 wg2
		local endpoint1 endpoint2 tunnel1 tunnel2

	kldload -n if_wg || atf_skip "This test requires if_wg and could not load it"

	wg=$(ifconfig wg create debug)

	# jc/jmin/jmax

	jc=255
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg jc $(($jc + 1))

	atf_check -s exit:0 -o ignore -e ignore \
		awg set $wg jc $jc

	jmin=1200
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg jmin $(($jmin + 1))

	atf_check -s exit:0 -o ignore -e ignore \
		awg set $wg jmin $jmin

	jmax=1280
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg jmin $(($jmax + 1))

	atf_check -s exit:0 -o ignore -e ignore \
		awg set $wg jmax $jmax

	jx=$(jot -r 1 1 $jmin)
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg jmin $jx jmax $jx

	jmin=$(jot -r 1 10 80)
	jdlt=$(jot -r 1 $jmin 1000)
	jmax=$(($jmin + $jdlt))
	atf_check -s exit:0 -o ignore \
		awg set $wg jmin $jmin jmax $jmax

	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg jmin $jmax jmax $jmin

	# s1/s2/s3/s4

	s1=1304
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg s1 $(($s1 + 1))

	atf_check -s exit:0 -o ignore -e ignore \
		awg set $wg s1 $s1

	s2=1360
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg s2 $(($s2 + 1))

	atf_check -s exit:0 -o ignore -e ignore \
		awg set $wg s2 $s2

	s3=1388
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg s3 $(($s3 + 1))

	atf_check -s exit:0 -o ignore -e ignore \
		awg set $wg s3 $s3

	s4=160
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg s4 $(($s4 + 1))

	atf_check -s exit:0 -o ignore -e ignore \
		awg set $wg s4 $s4

	# h1/h2/h3/h4

	h=$(jot -r 1 5 4294967295)
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 $h h2 $h

	h=$(jot -r 1 5 4294967295)
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 $h h3 $h

	h=$(jot -r 1 5 4294967295)
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 $h h4 $h

	h=$(jot -r 1 5 4294967295)
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 0 h2 $h h3 $h

	h=$(jot -r 1 5 4294967295)
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 0 h2 0 h3 $h h4 $h

	h=$(jot -r 1 5 4294967295)
	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 0 h2 $h h3 $h h4 0

	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 1234567-2234567 h2 2000000

	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 1234567-2234567 h2 1234567

	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 1234567-2234567 h2 1000000-2234567

	atf_check -s exit:1 -o ignore -e match:"Invalid argument" \
		awg set $wg h1 1234567-2234567 h2 2000000-2000010

	atf_check -s exit:0 -o ignore \
		awg set $wg $(awg_config)

	# check reset of magic headers
	atf_check -s exit:0 -o ignore \
		awg set $wg h1 0 h2 0 h3 0 h4 0

	atf_check -s exit:0 -o not-match:'h[1-4]:' -e empty \
		awg show $wg
}

awg_constraints_cleanup()
{
	for i in $(ifconfig -g wg); do
		ifconfig $i destroy
	done
}

atf_test_case "wide_range_parameters" "cleanup"
wide_range_parameters_head()
{
	atf_set descr 'Create a awg(4) and test wide range parameters'
	atf_set require.user root
}

wide_range_parameters_body()
{
	local epair pri1 pri2 pub1 pub2 wg1 wg2
		local endpoint1 endpoint2 tunnel1 tunnel2

	kldload -n if_wg || atf_skip "This test requires if_wg and could not load it"

	pri1=$(wg genkey)
	pri2=$(wg genkey)

	endpoint1=192.168.2.1
	endpoint2=192.168.2.2
	tunnel1=169.254.0.1
	tunnel2=169.254.0.2

	epair=$(vnet_mkepair)

	vnet_init

	vnet_mkjail wgtest1 ${epair}a
	vnet_mkjail wgtest2 ${epair}b

	awg_cfg=$(awg_config)

	jexec wgtest1 ifconfig ${epair}a ${endpoint1}/24 up
	jexec wgtest2 ifconfig ${epair}b ${endpoint2}/24 up

	wg1=$(jexec wgtest1 ifconfig wg create debug)
	echo "$pri1" | jexec wgtest1 wg set $wg1 listen-port 12345 \
		private-key /dev/stdin
	pub1=$(jexec wgtest1 wg show $wg1 public-key)

	wg2=$(jexec wgtest2 ifconfig wg create debug)
	echo "$pri2" | jexec wgtest2 wg set $wg2 listen-port 12345 \
		private-key /dev/stdin
	pub2=$(jexec wgtest2 wg show $wg2 public-key)

	atf_check -s exit:0 -o ignore \
		jexec wgtest1 wg set $wg1 peer "$pub2" \
		endpoint ${endpoint2}:12345 allowed-ips ${tunnel2}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest1 awg set $wg1 $awg_cfg
	atf_check -s exit:0 \
		jexec wgtest1 ifconfig $wg1 inet ${tunnel1}/24 up debug

	atf_check -s exit:0 -o ignore \
		jexec wgtest2 wg set $wg2 peer "$pub1" \
		endpoint ${endpoint1}:12345 allowed-ips ${tunnel1}/32
	atf_check -s exit:0 -o ignore \
		jexec wgtest2 awg set $wg2 $awg_cfg
	atf_check -s exit:0 \
		jexec wgtest2 ifconfig $wg2 inet ${tunnel2}/24 up debug

	# Generous timeout since the handshake takes some time.
	atf_check -s exit:0 -o ignore jexec wgtest1 ping -c 1 -t 5 $tunnel2
	atf_check -s exit:0 -o ignore jexec wgtest2 ping -c 1 $tunnel1
}

wide_range_parameters_cleanup()
{
	vnet_cleanup
}

atf_init_test_cases()
{
	atf_add_test_case "awg_configuration"
	atf_add_test_case "awg_constraints"
	atf_add_test_case "wide_range_parameters"
}
