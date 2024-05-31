#!/bin/bash

set -e
#set -x

# クライアントから(WAN)に向けたパケットの送信元アドレスを(router)のWAN側IPアドレスに変換
#
#           (WAN)
#             |
#             |
#          (router) ↑IPマスカレード
#          /       \
#         /         \
#    [client-1]   [client-2]


# ネームスペースの作成
ip netns add client-1
ip netns add client-2
ip netns add router
ip netns add WAN

# client-1 <---> router
ip link add veth0 netns client-1 type veth peer name router-veth1
ip netns exec client-1 ip addr add 10.0.1.1/24 dev veth0
ip netns exec client-1 ip link set veth0 up
ip link set router-veth1 netns router
ip netns exec router ip addr add 10.0.1.254/24 dev router-veth1
ip netns exec router ip link set router-veth1 up

# client-2 <---> router
ip link add veth0 netns client-2 type veth peer name router-veth2
ip netns exec client-2 ip addr add 10.0.2.1/24 dev veth0
ip netns exec client-2 ip link set veth0 up
ip link set router-veth2 netns router up
ip netns exec router ip addr add 10.0.2.254/24 dev router-veth2

# WAN <---> router
ip link add veth0 netns WAN type veth peer name router-veth0
ip netns exec WAN ip addr add 203.0.133.100/24 dev veth0
ip netns exec WAN ip link set veth0 up
ip link set router-veth0 netns router up
ip netns exec router ip addr add 203.0.133.254/24 dev router-veth0

# clientからrouterにデフォルトルート向ける
ip netns exec client-1 ip route add default via 10.0.1.254 dev veth0
ip netns exec client-2 ip route add default via 10.0.2.254 dev veth0

# routerのNAT設定、WANに向けてIP Masquerade
ip netns exec router sysctl -w net.ipv4.ip_forward=1 > /dev/null
ip netns exec router iptables -t nat -A POSTROUTING -o router-veth0 -j MASQUERADE

# IPアドレス表
cat << EOF
client-1 10.0.1.1
client-2 10.0.2.1
router   10.0.1.254
router   10.0.2.254
router   203.0.133.254
WAN      203.0.133.100
EOF

echo -e "\nclient-1からWANにping送ります..."
ip netns exec client-1 ping -c 3 -R 203.0.133.100
echo -e "\nWANからclient-1にping送ります..."
ip netns exec WAN ping -c 3 -R 10.0.1.1

# 片付け
ip --all delete

