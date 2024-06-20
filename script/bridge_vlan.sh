#!/bin/bash


# ブリッジにネームスペースを接続してVLANとサブネットで分離する
#
#         ns0
#         [veth0]
#           | [veth0.10](vid 10) 10.0.10.254/24
#           | [veth0.20](vid 20) 10.0.20.254/24
#           | 
#           | 
#           | 
#          [veth0](vid 10, 20) 
#        netnsbr0
#         [veth1](vid 10) <--> ns1 10.0.10.1/24
#         [veth2](vid 10) <--> ns2 10.0.10.2/24
#         [veth3](vid 20) <--> ns3 10.0.20.3/24
#         [veth4](vid 20) <--> ns4 10.0.20.4/24


# root権限確認
if [ "$(id -u)" != "0" ]; then
   echo "このスクリプトはroot権限で実行する必要があります" 1>&2
   exit 1
fi


# ネームスペース作成
ip netns add ns0
ip netns add ns1
ip netns add ns2
ip netns add ns3
ip netns add ns4
ip --all netns exec ip link set lo up > /dev/null

# vethペア作成して各ネームスペースに割り当てる
ip link add veth0 type veth peer veth0 netns ns0
ip link add veth1 type veth peer veth0 netns ns1
ip link add veth2 type veth peer veth0 netns ns2
ip link add veth3 type veth peer veth0 netns ns3
ip link add veth4 type veth peer veth0 netns ns4
ip --all netns exec ip link set veth0 up > /dev/null

# ns0にVLANインターフェースを作成し、IPアドレスを割り当てる
ip netns exec ns0 ip link add link veth0 name veth0.10 type vlan id 10
ip netns exec ns0 ip link set veth0.10 up
ip netns exec ns0 ip addr add 10.0.10.254/24 dev veth0.10

ip netns exec ns0 ip link add link veth0 name veth0.20 type vlan id 20
ip netns exec ns0 ip link set veth0.20 up
ip netns exec ns0 ip addr add 10.0.20.254/24 dev veth0.20

# ns1~4のIPアドレスをVLANに合わせて設定
ip netns exec ns1 ip addr add 10.0.10.1/24 dev veth0
ip netns exec ns2 ip addr add 10.0.10.2/24 dev veth0
ip netns exec ns3 ip addr add 10.0.20.3/24 dev veth0
ip netns exec ns4 ip addr add 10.0.20.4/24 dev veth0

# VLAN有効でブリッジ作成
ip link add netnsbr0 type bridge vlan_filtering 1 vlan_default_pvid 0
ip link set netnsbr0 up

# vethペアをブリッジに接続
ip link set veth0 master netnsbr0 up
ip link set veth1 master netnsbr0 up
ip link set veth2 master netnsbr0 up
ip link set veth3 master netnsbr0 up
ip link set veth4 master netnsbr0 up

# VLAN設定
# ns0に接続するブリッジのveth0をトランクポートに設定
bridge vlan add vid 10 dev veth0 tagged
bridge vlan add vid 20 dev veth0 tagged
# アクセスポートのvid設定
bridge vlan add vid 10 dev veth1 pvid untagged
bridge vlan add vid 10 dev veth2 pvid untagged
bridge vlan add vid 20 dev veth3 pvid untagged
bridge vlan add vid 20 dev veth4 pvid untagged

