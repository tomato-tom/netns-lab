#!/bin/bash

# Create network namespaces for node-1 and node-2
echo "Create network namespaces"
ip netns add node-1
ip netns add node-2
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

for i in {1..30}; do
	echo -n .
	sleep 0.1
done

# Ping from node-1 to node-2
echo -e "\nPing from node-1 to node-2"
ip netns exec node-1 ping -c 1 f::2

# Delete all network namespaces
echo -e "\nDelete all network namespaces"
ip --all netns delete

