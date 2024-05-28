#!/bin/bash -e

# host <--> rt1 <--> rt2 <--> ns1
#
# host 10.0.1.1/24 netns-veth0
# rt1  10.0.1.2/24 veth0
# rt1  10.0.2.1/24 veth1
# rt2  10.0.2.2/24 veth0
# rt2  10.0.3.1/24 veth1
# ns1  10.0.3.2/24 veth0


# ネームスペース作成
ip netns add rt1
ip netns add rt2
ip netns add ns1

# host[netns-veth0] <---> [veth0]rt1
ip link add netns-veth0 type veth peer name veth0 netns rt1
ip link set netns-veth0 up
ip address add 10.0.1.1/24 dev netns-veth0
ip netns exec rt1 ip link set veth0 up
ip netns exec rt1 ip address add 10.0.1.2/24 dev veth0

# rt1[veth0] <---> [veth0]rt2
ip link add veth1 netns rt1 type veth peer name veth0 netns rt2
ip netns exec rt1 ip link set veth1 up
ip netns exec rt1 ip address add 10.0.2.1/24 dev veth1
ip netns exec rt2 ip link set veth0 up
ip netns exec rt2 ip address add 10.0.2.2/24 dev veth0
ip netns exec rt1 sysctl -w net.ipv4.ip_forward=1 > /dev/null

# rt2[veth1] <---> [veth0]ns1
ip link add veth1 netns rt2 type veth peer name veth0 netns ns1
ip netns exec rt2 ip link set veth1 up
ip netns exec rt2 ip address add 10.0.3.1/24 dev veth1
ip netns exec ns1 ip link set veth0 up
ip netns exec ns1 ip address add 10.0.3.2/24 dev veth0
ip netns exec rt2 sysctl -w net.ipv4.ip_forward=1 > /dev/null


# ルーティング
ip route add 10.0.2.0/24 via 10.0.1.2
ip route add 10.0.3.0/24 via 10.0.1.2
ip netns exec rt1 ip route add 10.0.3.0/24 via 10.0.2.2
ip netns exec rt2 ip route add 10.0.1.0/24 via 10.0.2.1
ip netns exec ns1 ip route add default via 10.0.3.1


# hostsファイル作成
mkdir -p /etc/netns/rt1/
mkdir -p /etc/netns/rt2/
mkdir -p /etc/netns/ns1/

hosts=$(cat << EOF
10.0.1.1  host.ns
10.0.1.2  rt1.ns
10.0.2.1  rt1.ns
10.0.2.2  rt2.ns
10.0.3.1  rt2.ns
10.0.3.2  ns1.ns
EOF
)
echo "${hosts}" >> /etc/hosts
echo "${hosts}" > /etc/netns/rt1/hosts
echo "${hosts}" > /etc/netns/rt2/hosts
echo "${hosts}" > /etc/netns/ns1/hosts
echo "${hosts}"

# ping送信
message="ホストからns1にping送信します.............."
for ((i=0; i<"${#message}"; i++)); do
    echo -n ${message:i:1}
    sleep 0.1
done

echo
ping -c 1 -R ns1.ns

# 後片付け
# ip --all netns delete
# sed -i '/.ns/d' /etc/hosts
# rm -r /etc/netns/*

