#!/bin/bash -e

# ネットワークネームスペースでbonding
# ns1 o---o netnsbr0 o===o ns2
#
# ns1 veth0 192.168.1.1/24 o---o netnsbr0 en0
# ns2 bond0 192.168.1.2/24
# ns2 veth0 o---o netnsbr0 en1 
# ns2 veth1 o---o netnsbr0 en2

# ネームスペース作成
ip netns add ns1
ip netns add ns2
ip netns exec ns1 ip link set lo up
ip netns exec ns2 ip link set lo up

# ns1 o---o netnsbr0
ip link add veth0 netns ns1 type veth peer en0
ip link add netnsbr0 type bridge
ip link set en0 master netnsbr0 up
ip link set netnsbr0 up
ip netns exec ns1 ip addr add 192.168.1.1/24 dev veth0
ip netns exec ns1 ip link set veth0 up

# netnsbr0 o===o ns2
ip link add veth0 netns ns2 type veth peer en1
ip link add veth1 netns ns2 type veth peer en2
ip link set en1 master netnsbr0 up
ip link set en2 master netnsbr0 up

# bonding
ip netns exec ns2 ip link add bond0 type bond
ip netns exec ns2 ip link set veth0 master bond0
ip netns exec ns2 ip link set veth1 master bond0
ip netns exec ns2 ip addr add 192.168.1.2/24 dev bond0
ip netns exec ns2 ip link set bond0 up

echo bonding設定確認します.....
sleep 1
ip netns exec ns2 cat /proc/net/bonding/bond0

echo ns1からns2へping送信します.....
sleep 1
ip netns exec ns1 ping -c 3 192.168.1.2
sleep 1
ip netns exec ns2 ip -s -st link show dev bond0

# 片付け
#ip --all netns delete
#ip link del netnsbr0

