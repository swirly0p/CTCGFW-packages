#!/bin/sh

FW4=$(command -v fw4)

if [ -n "$FW4" ]; then
	#删除oray_vpn_vnc表
	#nft flush chain inet fw4 oray_vpn_vnc
	for nft in "input" "forward" "output"; do
		handles=$(nft -a list chain inet fw4 ${nft} |grep -E "oray_vpn_vnc" |awk -F '# handle ' '{print$2}')
		for handle in $handles; do
			nft delete rule inet fw4 ${nft} handle ${handle} 2>/dev/null
		done
	done
	for handle in $(nft -a list chains |grep -E "oray_vpn_vnc" |awk -F '# handle ' '{print$2}'); do
		nft delete chain inet fw4 handle ${handle} 2>/dev/null
	done

	#建立oray_vpn_vnc表
	nft add chain inet fw4 oray_vpn_vnc 2>/dev/null
	nft insert rule inet fw4 oray_vpn_vnc iifname "oray_vnc" oifname "br-lan" counter accept 2>/dev/null
	nft insert rule inet fw4 oray_vpn_vnc iifname "br-lan" oifname "oray_vnc" counter accept 2>/dev/null
	nft insert rule inet fw4 oray_vpn_vnc iifname "oray_vnc" counter accept 2>/dev/null
	nft insert rule inet fw4 input counter jump oray_vpn_vnc 2>/dev/null
	nft insert rule inet fw4 output counter jump oray_vpn_vnc 2>/dev/null
	nft insert rule inet fw4 forward counter jump oray_vpn_vnc 2>/dev/null
else
	#删除oray_vpn_vnc表
	iptables -w -t filter -F oray_vpn_vnc
	while true;
	do
		iptables -w -t filter -D INPUT -j oray_vpn_vnc 2>/dev/null
		[ $? -ne 0 ] && break
	done

	while true;
	do
		iptables -w -t filter -D FORWARD -j oray_vpn_vnc 2>/dev/null
		[ $? -ne 0 ] && break
	done

	while true;
	do
		iptables -w -t filter -D OUTPUT -j oray_vpn_vnc 2>/dev/null
		[ $? -ne 0 ] && break
	done
	iptables -w -t filter -X oray_vpn_vnc

	#建立oray_vpn_vnc表
	iptables -w -t filter -N oray_vpn_vnc
	iptables -w -t filter -I oray_vpn_vnc -i oray_vnc -o br-lan -j ACCEPT
	iptables -w -t filter -I oray_vpn_vnc -o oray_vnc -i br-lan -j ACCEPT
	iptables -w -t filter -I INPUT 1 -j oray_vpn_vnc
	iptables -w -t filter -I OUTPUT 1 -j oray_vpn_vnc
	iptables -w -t filter -I FORWARD 1 -j oray_vpn_vnc
	iptables -w -t filter -I oray_vpn_vnc -i oray_vnc -j ACCEPT
fi
