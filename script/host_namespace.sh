#!/bin/bash

# ホストとネットワーク・ネームスペース間で通信
# host veth0 10.0.0.1/24   ホスト
# ns1  veth0 10.0.0.2/24   ネームスペース

# root権限確認
if [ "$(id -u)" != "0" ]; then
   echo "このスクリプトはroot権限で実行する必要があります" 1>&2
   exit 1
fi

# リンクアップ後数秒待たないとpingできないから時間稼ぎのための関数??
typing () {
	while IFS= read -r -n1 char; do
		printf "%s" "$char"
		sleep 0.1
	done <<< $1
	echo
}

# create namespace
ip netns add ns1

# host <---> ns1
ip link add veth0 type veth peer name veth0 netns ns1
ip address add 10.0.0.1/24 dev veth0
ip link set veth0 up
ip netns exec ns1 ip address add 10.0.0.2/24 dev veth0
ip netns exec ns1 ip link set veth0 up

# ping ns1 --> host
typing "ping from ns1 to host ....................."
ip netns exec ns1 ping -R -c 1 10.0.0.1

# delete namespace
#ip netns delete ns1
