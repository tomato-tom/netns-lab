#!/bin/bash

# IPv6 communication between two namespaces
#
# this script creates two network namespaces (node-1 and node-2), 
# assigns virtual ethernet interfaces to them, 
# sets IPv6 addresses, and verifies the connectivity with a ping command.

# [node-1]o----o[node2]
#
# name   nic   ip address
# node-1 veth1  f::1
# node-2 veth2  f::2

# root権限確認
if [ "$(id -u)" != "0" ]; then
   echo "このスクリプトはroot権限で実行する必要があります" 1>&2
   exit 1
fi

# Create network namespaces for node-1 and node-2
echo "Create network namespaces"
ip netns add node-1
ip netns add node-2
ip netns exec node-1 ip link set lo up
ip netns exec node-2 ip link set lo up
ip netns list

# Create virtual ethernet pair veth1 and veth2
ip link add veth1 type veth peer name veth2

# Move veth1 to node-1 and veth2 to node-2
ip link set veth1 netns node-1
ip link set veth2 netns node-2

# Assign IPv6 addresses to veth1 and veth2
ip netns exec node-1 ip -6 address add f::1/64 dev veth1
ip netns exec node-2 ip -6 address add f::2/64 dev veth2

# Bring up veth1 and veth2
ip netns exec node-1 ip link set veth1 up
ip netns exec node-2 ip link set veth2 up

# Ping node-1 --> node-2
echo -e "\nPing from node-1 to node-2"
ip netns exec node-1 ping -c 5 f::2

# Delete namespaces
#echo -e "\nDelete all network namespaces"
#ip --all netns delete

