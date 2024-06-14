#!/bin/bash

# ネームスペースのhostsファイル作成サンプル
# 
# ネームスペース作成
ip netns add ns1
ip netns exec ns1 ip link set lo up
ip netns add ns2
ip netns exec ns2 ip link set lo up

# 接続
ip link add veth0 netns ns1 type veth peer veth0 netns ns2
ip netns exec ns1 ip addr add 10.0.0.1/24 dev veth0
ip netns exec ns1 ip -6 addr add fa::1/64 dev veth0
ip netns exec ns1 ip link set veth0 up
ip netns exec ns2 ip addr add 10.0.0.2/24 dev veth0
ip netns exec ns2 ip -6 addr add fa::2/64 dev veth0
ip netns exec ns2 ip link set veth0 up

hosts=$(cat << EOF
10.0.0.1   ns1.ns
10.0.0.2   ns2.ns
fa::1      ns1.ns
fa::2      ns2.ns
EOF
)

mkdir -p /etc/netns/ns1
mkdir -p /etc/netns/ns2
echo "${hosts}" >> /etc/netns/ns1/hosts
echo "${hosts}" >> /etc/netns/ns2/hosts
cat /etc/netns/ns1/hosts

#rm -r /etc/netns/*
#ip --all netns delete

