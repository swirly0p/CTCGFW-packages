#!/bin/sh

FW4=$(command -v fw4)

if [ -n "$FW4" ]; then
	#删除oray_vpn_p2p表
	#nft flush chain inet fw4 oray_vpn_p2p
	handles=$(nft -a list chain inet fw4 input|grep -E "oray_vpn_p2p" |awk -F '# handle ' '{print$2}')
	for handle in $handles; do
		nft delete rule inet fw4 input handle ${handle} 2>/dev/null
	done
	for handle in $(nft -a list chains |grep -E "oray_vpn_p2p" |awk -F '# handle ' '{print$2}'); do
		nft delete chain inet fw4 handle ${handle} 2>/dev/null
	done

	#建立oray_vpn_p2p表
	nft add chain inet fw4 oray_vpn_p2p 2>/dev/null
	nft insert rule inet fw4 oray_vpn_p2p udp dport $2 counter accept 2>/dev/null
	nft insert rule inet fw4 oray_vpn_p2p udp dport 1900 counter accept 2>/dev/null
	nft insert rule inet fw4 input counter jump oray_vpn_p2p 2>/dev/null
else
	#删除oray_vpn_p2p表
	iptables -w -t filter -F oray_vpn_p2p
	while true;
	do
		iptables -w -t filter -D INPUT -j oray_vpn_p2p 2>/dev/null
		[ $? -ne 0 ] && break
	done
	iptables -w -t filter -X oray_vpn_p2p

	#建立oray_vpn_p2p表
	iptables -w -t filter -N oray_vpn_p2p
	iptables -w -t filter -I oray_vpn_p2p -p udp --dport $2 -j ACCEPT
	iptables -w -t filter -I oray_vpn_p2p -p udp --dport 1900 -j ACCEPT
	iptables -w -t filter -I INPUT 1 -j oray_vpn_p2p
fi
