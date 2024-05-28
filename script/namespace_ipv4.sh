#!/bin/bash

# ２つのネームスペース間のipv4通信
# node-1 veth1 10.0.0.1
# node-2 veth2 10.0.0.2

# Create network namespaces for node-1 and node-2
echo "Create network namespaces"
ip netns add node-1
ip netns add node-2
ip netns list

# Create virtual ethernet pair veth1 and veth2
ip link add veth1 type veth peer veth2

# Move veth1 to node-1 and veth2 to node-2
ip link set veth1 netns node-1
ip link set veth2 netns node-2

# Assign IPv4 addresses to veth1 and veth2
ip netns exec node-1 ip addr add 10.0.0.1/24 dev veth1
ip netns exec node-2 ip addr add 10.0.0.2/24 dev veth2

# Bring up veth1 and veth2
ip netns exec node-1 ip link set veth1 up
ip netns exec node-2 ip link set veth2 up

# ３秒ほど待たないとアップしない
for i in {1..30}; do
	echo -n .
	sleep 0.1
done

# Ping from node-1 to node-2
echo -e "\nPing from node-1 to node-2"
ip netns exec node-1 ping -R -c 1 10.0.0.2

# Delete all network namespaces
echo -e "\nDelete all network namespaces"
ip --all netns delete

