#!/bin/bash

# Dockerコンテナとネットワークネームスペースをvethペアで接続、ping送る
# ct1 o---o ns1

# root権限確認
if [ "$(id -u)" != "0" ]; then
   echo "このスクリプトはroot権限で実行する必要があります" 1>&2
   exit 1
fi

# コンテナとネームスペースを作成
docker run --privileged --network none -itd --name ct1 alpine
ip netns add ns1

# vethペアを作成
ip link add veth-ct1 type veth peer name veth-ns1 netns ns1

# veth-ct1をコンテナのネットワークネームスペースに設定し、IPアドレスを割り当てる
pid=$(docker inspect --format '{{.State.Pid}}' ct1)
ln -s /proc/$pid/ns/net /var/run/netns/$pid
ip link set veth-ct1 netns $pid
docker exec -it ct1 ip addr add 172.18.0.2/16 dev veth-ct1
docker exec -it ct1 ip link set veth-ct1 up

# veth-ns1をns1のネットワークネームスペースに設定し、IPアドレスを割り当てる
ip netns exec ns1 ip addr add 172.18.0.1/16 dev veth-ns1
ip netns exec ns1 ip link set veth-ns1 up

# ping送信 ns1 --> ct1
echo ns1からct1にping送信します
ip netns exec ns1 ping -c 3 172.18.0.2

# 後片付け
docker stop ct1 && docker rm ct1
rm /var/run/netns/$pid
ip netns delete ns1

