#!/bin/bash

# Network namespaceによるネットワークテスト環境の構築
# https://www.bit-hive.com/articles/20230315
# host <--> ns1 <--> ns2 <--> ns3

# create namespace
ip netns add ns1
ip netns add ns2
ip netns add ns3

# global <-> ns1 veth
ip link add veth0 type veth peer veth0 netns ns1
ip addr add 10.0.1.1/24 dev veth0
ip link set veth0 up
ip netns exec ns1 ip addr add 10.0.1.10/24 dev veth0
ip netns exec ns1 ip link set veth0 up

# ns1 <-> ns2 veth
ip link add veth1 netns ns1 type veth peer veth1 netns ns2
ip netns exec ns1 ip addr add 10.0.2.10/24 dev veth1
ip netns exec ns1 ip link set veth1 up
ip netns exec ns2 ip addr add 10.0.2.20/24 dev veth1
ip netns exec ns2 ip link set veth1 up
ip netns exec ns1 sysctl -w net.ipv4.ip_forward=1

# ns2 <-> ns3 veth
ip link add veth2 netns ns2 type veth peer veth2 netns ns3
ip netns exec ns2 ip addr add 10.0.3.20/24 dev veth2
ip netns exec ns2 ip link set veth2 up
ip netns exec ns3 ip addr add 10.0.3.30/24 dev veth2
ip netns exec ns3 ip link set veth2 up
ip netns exec ns2 sysctl -w net.ipv4.ip_forward=1

# routing
ip route add 10.0.2.0/24 via 10.0.1.10
ip route add 10.0.3.0/24 via 10.0.1.10
ip netns exec ns1 ip route add 10.0.3.0/24 via 10.0.2.20
ip netns exec ns2 ip route add 10.0.1.0/24 via 10.0.2.10
ip netns exec ns3 ip route add 10.0.1.0/24 via 10.0.3.20
ip netns exec ns3 ip route add 10.0.2.0/24 via 10.0.3.20

echo "host 10.0.1.1"
echo "ns1 10.0.1.10"
echo "ns1 10.0.2.10"
echo "ns2 10.0.2.20"
echo "ns2 10.0.3.20"
echo "ns3 10.0.3.30"
