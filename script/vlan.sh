#!/bin/bash

# ネットワークアドレス 10.0.0.0/24
# ブリッジにネームスペースを接続してVLANで分離する
# netnsbr0[veth1](vid 10) <--> ns1 10.0.0.1
#         [veth2](vid 10) <--> ns1 10.0.0.2
#         [veth3](vid 20) <--> ns1 10.0.0.3
#         [veth4](vid 20) <--> ns1 10.0.0.4


# ネームスペース作成
ip netns add ns1
ip netns add ns2
ip netns add ns3
ip netns add ns4

# VLAN有効でブリッジ作成
ip link add netnsbr0 type bridge vlan_filtering 1
ip link set netnsbr0 up

# vethペア作成して各ネームスペースに割り当てる
ip link add veth1 type veth peer veth0 netns ns1
ip link add veth2 type veth peer veth0 netns ns2
ip link add veth3 type veth peer veth0 netns ns3
ip link add veth4 type veth peer veth0 netns ns4
ip netns exec ns1 ip link set veth0 up
ip netns exec ns2 ip link set veth0 up
ip netns exec ns3 ip link set veth0 up
ip netns exec ns4 ip link set veth0 up
ip netns exec ns1 ip addr add 10.0.0.1/24 dev veth0
ip netns exec ns2 ip addr add 10.0.0.2/24 dev veth0
ip netns exec ns3 ip addr add 10.0.0.3/24 dev veth0
ip netns exec ns4 ip addr add 10.0.0.4/24 dev veth0

# vethペアをブリッジに接続
ip link set veth1 master netnsbr0 up
ip link set veth2 master netnsbr0 up
ip link set veth3 master netnsbr0 up
ip link set veth4 master netnsbr0 up

# この段階ではネームスペース同士全てにping通る
# 以降の設定でL2ネットワーク分離

# VLAN設定
bridge vlan add vid 10 dev veth1 pvid untagged
bridge vlan add vid 10 dev veth2 pvid untagged
bridge vlan add vid 20 dev veth3 pvid untagged
bridge vlan add vid 20 dev veth4 pvid untagged

# デフォルトのVLANルールを削除
bridge vlan del dev veth1 vid 1
bridge vlan del dev veth2 vid 1
bridge vlan del dev veth3 vid 1
bridge vlan del dev veth4 vid 1


cat << EOF
ns1 10.0.0.1 vid 10
ns2 10.0.0.2 vid 10
ns3 10.0.0.3 vid 20
ns4 10.0.0.4 vid 20

EOF

# 片付け
#ip --all netns delete
#ip link del netnsbr0

