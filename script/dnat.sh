#!/bin/bash


# クライアントからrouter2に向けたパケットの送信先アドレスをserverのIPアドレスに変換
#
#   [cliant] --- (router1) ↓SNAT
#                   |
#                   |
#                (router2) ↓DNAT
#                   |     
#                   |      
#               [server01]

# cliant   veth0 203.0.113.10/24
# router1  en0   203.0.113.20/24
#          en1   198.51.100.12/24
# router2  en0   198.51.100.234/24
#          en1   192.168.10.254/24
# server   veth0 192.168.10.1/24

# create nemespaces
ip netns add client
ip netns add router1
ip netns add router2
ip netns add server
ip netns exec client ip link set lo up
ip netns exec router1 ip link set lo up
ip netns exec router2 ip link set lo up
ip netns exec server ip link set lo up

# client <---> router1
ip link add veth0 netns client type veth peer en0 netns router1
ip netns exec client ip addr add 203.0.113.10/24 dev veth0
ip netns exec client ip link set veth0 up
ip netns exec router1 ip addr add 203.0.113.20/24 dev en0
ip netns exec router1 ip link set en0 up

# router1 <---> router2
ip link add en1 netns router1 type veth peer en0 netns router2
ip netns exec router1 ip addr add 198.51.100.12/24 dev en1
ip netns exec router1 ip link set en1 up
ip netns exec router2 ip addr add 198.51.100.234/24 dev en0
ip netns exec router2 ip link set en0 up

# router2 <---> server
ip link add en1 netns router2 type veth peer veth0 netns server
ip netns exec router2 ip addr add 192.168.10.254/24 dev en1
ip netns exec router2 ip link set en1 up
ip netns exec server ip addr add 192.168.10.1/24 dev veth0
ip netns exec server ip link set veth0 up

# routing 
ip netns exec client ip route add default via 203.0.113.20 dev veth0
ip netns exec server ip route add default via 192.168.10.254 dev veth0
ip netns exec router1 sysctl -w net.ipv4.ip_forward=1 > /dev/null
ip netns exec router2 sysctl -w net.ipv4.ip_forward=1 > /dev/null

# NAT
ip netns exec router1 iptables \
 -t nat \
 -A POSTROUTING \
 -o en1 \
 -j MASQUERADE
ip netns exec router2 iptables \
 -t nat \
 -A PREROUTING \
 -d 198.51.100.234 \
 -j DNAT \
 --to-destination 192.168.10.1

# IP Addresses
cat << EOF
cliant    203.0.113.10
router1   203.0.113.20
          198.51.100.12
router2   198.51.100.234
          192.168.10.254
server    192.168.10.1
EOF

echo -e "\nclientからrouter2にping送ります..."
ip netns exec client  ping -c 1 -R 198.51.100.234
echo -e "\nclientから直接serverにping送ります..."
ip netns exec client ping -c 1 -R 192.168.10.1

