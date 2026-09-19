
hp() {
	local max32bit=4294967295
	local h=$(jot -r 1 5 $max32bit)
	local d=$(jot -r 1 0 65365)
	hm=$((h + d))
	if [ $hm -gt $max32bit ]; then
		hm=$max32bit
	fi
	echo "$h-$hm"
}

check_h_overlap()
{
	h=$1
	ha=${h%%-*}
	hb=${h#*-}
	shift
	for i in "$@"; do
		ia=${i%%-*}
		ib=${i#*-}

		if [ $hb -ge $ia ] && [ $ib -ge $ha ]; then
			return 1
		fi
	done
	return 0
}

awg_config() {
	for i in 1 2 3 4; do
		jc=$(jot -r 1 3 10)
		jmin=$(jot -r 1 0 1200)
		jmax=$(jot -r 1 $jmin 1280)

		s1=$(jot -r 1 15 1304)
		s2=$(jot -r 1 15 1360)
		s3=$(jot -r 1 15 1388)
		s4=$(jot -r 1 15 10)

		h1=$(hp)
		h2=$(hp)
		h3=$(hp)
		h4=$(hp)

		# check overlaps
		check_h_overlap $h1 $h2 $h3 $h4 || continue
		check_h_overlap $h2 $h1 $h3 $h4 || continue
		check_h_overlap $h3 $h1 $h2 $h4 || continue
		check_h_overlap $h4 $h1 $h2 $h3 || continue

		break
	done

	# i1="<b 0xdeadbeef><c><b 0xdeadbeef><t><r 10><rd 8><c><rc 16>"

	cfg="jc $jc jmin $jmin jmax $jmax
		s1 $s1 s2 $s2 s3 $s3 s4 $s4
		h1 $h1 h2 $h2 h3 $h3 h4 $h4
		content-padding-addition 8-64
		rekey-after-time 110-120
		rekey-timeout 5-7
		reject-after-time 180-190
		keepalive-timeout 10-12
		max-handshake-attempts 18-20
		random-trailers on
		disable-cookies on"

	echo $cfg
}

awg_config_get() {
	key="$1"
	shift
	echo "$*" | awk -v k="$key" '{for(i=1;i<NF;i+=2) if($i==k){print $(i+1); exit}}'
}

c=$(awg_config)
key_file=/tmp/awg3-header-protection.key
awg genkey > "$key_file"
c="$c header-protection-key $key_file"

echo "awg set wg0 $c"
echo

cat <<EOF
Jc = $(awg_config_get jc $c)
Jmin = $(awg_config_get jmin $c)
Jmax = $(awg_config_get jmax $c)
S1 = $(awg_config_get s1 $c)
S2 = $(awg_config_get s2 $c)
S3 = $(awg_config_get s3 $c)
S4 = $(awg_config_get s4 $c)
H1 = $(awg_config_get h1 $c)
H2 = $(awg_config_get h2 $c)
H3 = $(awg_config_get h3 $c)
H4 = $(awg_config_get h4 $c)
HeaderProtectionKey = $(cat "$key_file")
ContentPaddingAddition = $(awg_config_get content-padding-addition $c)
RekeyAfterTime = $(awg_config_get rekey-after-time $c)
RekeyTimeout = $(awg_config_get rekey-timeout $c)
RejectAfterTime = $(awg_config_get reject-after-time $c)
KeepaliveTimeout = $(awg_config_get keepalive-timeout $c)
MaxHandshakeAttempts = $(awg_config_get max-handshake-attempts $c)
RandomTrailers = $(awg_config_get random-trailers $c)
DisableCookies = $(awg_config_get disable-cookies $c)
EOF
