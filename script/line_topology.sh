#!/bin/bash -e

# １から最大６６までのネットワークネームスペースを作成します
# 両端ノードから相互にping通るようにルーティングします
#
# node01 <--> node02 <--> node03 <-->..... node66
#

# root権限確認
if [ "$(id -u)" != "0" ]; then
   echo "このスクリプトはroot権限で実行する必要があります" 1>&2
   exit 1
fi


# 引数確認、指定しない場合は5ノード作成
count=5
if [[ $1 =~ ^[0-9]{1,2}$ ]]; then
    if [ $1 -ne 0 ] && [ $1 -lt 66 ]; then
        count=$(( 10#${1} ))
    fi
fi
echo $count ノード作成します

# -----------------------------------------------------------------
# ノード作成
create () {
	local node=$(printf node%02d ${1})
	ip netns add $node
	ip netns exec $node ip link set lo up
}

# 接続 nodeA[veth0] <--> [veth1]nodeB
connection () {
    local subnet=$1
	local nodeA=$(printf node%02d ${subnet})
	local nodeB=$(printf node%02d $((subnet + 1)))

	ip link add veth0 netns $nodeA type veth peer veth1 netns $nodeB
	ip netns exec $nodeA ip address add 1.1.${subnet}.1/24 dev veth0
	ip netns exec $nodeA ip link set veth0 up
	ip netns exec $nodeB ip address add 1.1.${subnet}.2/24 dev veth1
	ip netns exec $nodeB ip link set veth1 up
}

# ルーティング
routing () {
    local subnet=$1
	local node=$(printf node%02d ${subnet})

	# 両端ノードのルーティング
	if [ $1 -eq 1 ]; then
		ip netns exec $node ip route add default via 1.1.${subnet}.2 dev veth0
		return
	elif [ $1 -eq $count ]; then
		ip netns exec $node ip route add default via 1.1.$((subnet - 1)).1 dev veth1
		return
	fi

	# 中間ノードのルーティング
	# node[veth0] --> 順方向
	local subnet=$(($1+1))
	local nexthop="1.1.${1}.2"
    local network

	for ((s=$subnet; s < $count; s++)); do
		network="1.1.${s}.0/24"
		ip netns exec $node ip route add $network via $nexthop dev veth0
	done
	# node[veth1] --> 逆方向
	local subnet=$(($1-2))
	local nexthop="1.1.$(($1-1)).1"
	for ((s=$subnet; s >= 1; s--)); do
		network="1.1.${s}.0/24"
		ip netns exec $node ip route add $network via $nexthop dev veth1
	done

	# パケット転送を有効化
	ip netns exec $node sysctl -w net.ipv4.ip_forward=1 > /dev/null
}
# -----------------------------------------------------------------------

# ノード作成
for ((i=1; i <= $count; i++)); do
	create $i
done
#ip netns list | head

# 接続
for ((i=1; i < $count; i++)); do
	[ $count -lt 2 ] && break
	connection $i
done

# ルーティング
for ((i=1; i <= $count; i++)); do
	[ $count -lt 3 ] && break
	routing $i
done

# IPアドレス表、先頭末尾の３つのみ表示
for ((i=1; i <= $count; i++)); do
	node=$(printf node%02d ${i})
	if [ $i -gt 3 ] && [ $((count - i)) -gt 3 ];
		then continue
	fi
	echo -n "$node "
	ip netns exec $node hostname -I
done


