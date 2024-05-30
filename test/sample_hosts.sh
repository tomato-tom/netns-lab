#!/bin/bash

# ネームスペースのhostsファイル作成サンプル

hosts=$(cat << EOF
10.0.0.1   ns1.ns
10.0.0.2   ns2.ns
10.0.0.3   ns3.ns
fa::1      ns1.ns
fa::2      ns2.ns
fa::3      ns3.ns
EOF
)

mkdir -p /etc/netns/ns1
mkdir -p /etc/netns/ns2
mkdir -p /etc/netns/ns3
ip netns exec ns1 echo "${hosts}" >> /etc/netns/ns1/hosts
ip netns exec ns2 echo "${hosts}" >> /etc/netns/ns2/hosts
ip netns exec ns3 echo "${hosts}" >> /etc/netns/ns3/hosts
cat /etc/netns/ns1/hosts

#rm -r /etc/netns/*

