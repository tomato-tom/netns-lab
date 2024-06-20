#!/bin/bash -e

# ネットワークネームスペースでbonding
# ns1 o===o ns2
#
# ns1 bond0 192.168.1.1/24
# ns1 veth0 o---o ns2 veth0
# ns1 veth1 o---o ns2 veth1
# ns2 bond0 192.168.1.2/24

# ネームスペース作成
ip netns add ns1
ip netns add ns2
ip netns exec ns1 ip link set lo up
ip netns exec ns2 ip link set lo up

# vethペア作成
ip link add veth0 netns ns1 type veth peer veth0 netns ns2
ip link add veth1 netns ns1 type veth peer veth1 netns ns2

# bonding
ip netns exec ns1 ip link add bond0 type bond
ip netns exec ns1 ip link set veth0 master bond0
ip netns exec ns1 ip link set veth1 master bond0
ip netns exec ns1 ip addr add 192.168.1.1/24 dev bond0
ip netns exec ns1 ip link set bond0 up

ip netns exec ns2 ip link add bond0 type bond
ip netns exec ns2 ip link set veth0 master bond0
ip netns exec ns2 ip link set veth1 master bond0
ip netns exec ns2 ip addr add 192.168.1.2/24 dev bond0
ip netns exec ns2 ip link set bond0 up

echo bonding設定確認します.....
sleep 1
ip netns exec ns1 cat /proc/net/bonding/bond0

echo ns1からns2へping送信します.....
sleep 1
ip netns exec ns1 ping -c 3 192.168.1.2
sleep 1
ip netns exec ns1 ip -s -st link show dev bond0

