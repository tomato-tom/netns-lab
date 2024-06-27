#!/bin/bash

#                   10.0.0.254   [port0] o---o [veth0]ns1 10.0.0.1/24
# br0(SVI)[VLAN100] 10.0.100.254 [port1] o---o [veth1]ns2 10.0.100.1/24
#    (SVI)[VLAN200] 10.0.200.254 [port2] o---o [veth2]ns3 10.0.200.1/24
#             
# ns1からns2,ns3の相互通信可能で、ns2(VLAN100)からns3(VLAN200)は通信遮断


# ネームスペース作成
ip netns add ns1
ip netns exec ns1 ip link set lo up
ip netns add ns2
ip netns exec ns2 ip link set lo up
ip netns add ns3
ip netns exec ns3 ip link set lo up
ip netns add l3br0
ip netns exec l3br0 ip link set lo up

# vethペア接続
ip link add port0 netns l3br0 type veth peer veth0 netns ns1
ip link add port1 netns l3br0 type veth peer veth1 netns ns2
ip link add port2 netns l3br0 type veth peer veth2 netns ns3

ip netns exec ns1 ip address add 10.0.0.1/24 dev veth0
ip netns exec ns1 ip link set veth0 up
ip netns exec ns2 ip address add 10.0.100.1/24 dev veth1
ip netns exec ns2 ip link set veth1 up
ip netns exec ns3 ip address add 10.0.200.1/24 dev veth2
ip netns exec ns3 ip link set veth2 up

# l3br0内にブリッジの作成
ip netns exec l3br0 ip link add br0 type bridge vlan_filtering 1
ip netns exec l3br0 ip addr add 10.0.0.254/24 dev br0
ip netns exec l3br0 ip link set br0 up

# 仮想ポートの作成
ip netns exec l3br0 ip link set port0 master br0
ip netns exec l3br0 ip link set port1 master br0
ip netns exec l3br0 ip link set port2 master br0
ip netns exec l3br0 ip link set port0 up
ip netns exec l3br0 ip link set port1 up
ip netns exec l3br0 ip link set port2 up

# VLAN 100 と 200 の SVI 設定
ip netns exec l3br0 ip link add link br0 name br0.100 type vlan id 100
ip netns exec l3br0 bridge vlan add vid 100 dev br0 self
ip netns exec l3br0 ip link set br0.100 up
ip netns exec l3br0 ip addr add 10.0.100.254/24 dev br0.100
ip netns exec l3br0 ip link add link br0 name br0.200 type vlan id 200
ip netns exec l3br0 bridge vlan add vid 200 dev br0 self
ip netns exec l3br0 ip link set br0.200 up
ip netns exec l3br0 ip addr add 10.0.200.254/24 dev br0.200

# BridgeポートのVLAN の設定
ip netns exec l3br0 bridge vlan add vid 100 dev port1 pvid untagged
ip netns exec l3br0 bridge vlan add vid 200 dev port2 pvid untagged
ip netns exec l3br0 bridge vlan del vid 1 dev port1
ip netns exec l3br0 bridge vlan del vid 1 dev port2

# routing
ip netns exec ns1 ip route add default via 10.0.0.254 dev veth0
ip netns exec ns2 ip route add default via 10.0.100.254 dev veth1
ip netns exec ns3 ip route add default via 10.0.200.254 dev veth2

# VLAN 100とVLAN 200の相互トラフィックをブロック
ip netns exec l3br0 iptables -A FORWARD -i br0.100 -o br0.200 -j DROP
ip netns exec l3br0 iptables -A FORWARD -i br0.200 -o br0.100 -j DROP

