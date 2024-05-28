#!/bin/bash 

# ルーター３つを接続
# ルーターそれぞれにブリッジを接続
# 各ブリッジにノード２つずつ接続
#
#                     1.1.1.0/24
#             rt1 <--> netnsbr1|<--> ns1
#              |               |
#              |               |<--> ns2
#   2.1.1.0/24 |               
#              |        1.1.2.0/24
#             rt2 <--> netnsbr2|<--> ns3
#              |               |
#              |               |<--> ns4
#   2.1.2.0/24 |                
#              |      1.1.3.0/24
#             rt3 <--> netnsbr3|<--> ns5
#                              |
#                              |<--> ns6

# IPアドレス
#   rt1 en1  2.1.1.1
#   rt2 en2  2.1.1.2

#   rt2 en1  2.1.2.1
#   rt3 en2  2.1.2.2

#   rt1 en0  1.1.1.254 --> netnsbr1en0
#   ns1 eth0 1.1.1.1   --> netnsbr1en1
#   ns2 eth0 1.1.1.2   --> netnsbr1en2

#   rt2 en0  1.1.2.254 --> netnsbr2en0
#   ns3 eth0 1.1.2.1   --> netnsbr2en1
#   ns4 eth0 1.1.2.2   --> netnsbr2en2

#   rt3 en0  1.1.3.254 --> netnsbr3en0
#   ns5 eth0 1.1.3.1   --> netnsbr3en1
#   ns6 eth0 1.1.3.2   --> netnsbr3en2


# ノード作成
for i in {1..6}; do
	ip netns add ns$i
	ip netns exec ns$i ip link set dev lo up
	[ $i -gt 3 ] && continue
	ip netns add rt$i
	ip netns exec rt$i ip link set dev lo up
	ip link add netnsbr$i type bridge
	ip link set netnsbr$i up
done

# 接続
# rt1 <--> rt2
ip link add en1 netns rt1 type veth peer en2 netns rt2
ip netns exec rt1 ip address add 2.1.1.1/24 dev en1
ip netns exec rt1 ip link set dev en1 up
ip netns exec rt2 ip address add 2.1.1.2/24 dev en2
ip netns exec rt2 ip link set dev en2 up

# rt2 <--> rt3
ip link add en1 netns rt2 type veth peer en2 netns rt3
ip netns exec rt2 ip address add 2.1.2.1/24 dev en1
ip netns exec rt2 ip link set dev en1 up
ip netns exec rt3 ip address add 2.1.2.2/24 dev en2
ip netns exec rt3 ip link set dev en2 up

# rt1 <--> netnsbr1
ip link add en0 netns rt1 type veth peer netnsbr1en0
ip netns exec rt1 ip address add 1.1.1.254/24 dev en0
ip netns exec rt1 ip link set dev en0 up
ip link set netnsbr1en0 master netnsbr1
ip link set netnsbr1en0 up

# rt2 <--> netnsbr2
ip link add en0 netns rt2 type veth peer netnsbr2en0
ip netns exec rt2 ip address add 1.1.2.254/24 dev en0
ip netns exec rt2 ip link set dev en0 up
ip link set netnsbr2en0 master netnsbr2
ip link set netnsbr2en0 up

# rt3 <--> netnsbr3
ip link add en0 netns rt3 type veth peer netnsbr3en0
ip netns exec rt3 ip address add 1.1.3.254/24 dev en0
ip netns exec rt3 ip link set dev en0 up
ip link set netnsbr3en0 master netnsbr3
ip link set netnsbr3en0 up


# ns1 <--> netnsbr1
ip link add eth0 netns ns1 type veth peer netnsbr1en1
ip netns exec ns1 ip address add 1.1.1.1/24 dev eth0
ip netns exec ns1 ip link set dev eth0 up
ip link set netnsbr1en1 master netnsbr1
ip link set netnsbr1en1 up

# ns2 <--> netnsbr1
ip link add eth0 netns ns2 type veth peer netnsbr1en2
ip netns exec ns2 ip address add 1.1.1.2/24 dev eth0
ip netns exec ns2 ip link set dev eth0 up
ip link set netnsbr1en2 master netnsbr1
ip link set netnsbr1en2 up

# ns3 <--> netnsbr2
ip link add eth0 netns ns3 type veth peer netnsbr2en1
ip netns exec ns3 ip address add 1.1.2.1/24 dev eth0
ip netns exec ns3 ip link set dev eth0 up
ip link set netnsbr2en1 master netnsbr2
ip link set netnsbr2en1 up

# ns4 <--> netnsbr2
ip link add eth0 netns ns4 type veth peer netnsbr2en2
ip netns exec ns4 ip address add 1.1.2.2/24 dev eth0
ip netns exec ns4 ip link set dev eth0 up
ip link set netnsbr2en2 master netnsbr2
ip link set netnsbr2en2 up

# ns5 <--> netnsbr3
ip link add eth0 netns ns5 type veth peer netnsbr3en1
ip netns exec ns5 ip address add 1.1.3.1/24 dev eth0
ip netns exec ns5 ip link set dev eth0 up
ip link set netnsbr3en1 master netnsbr3
ip link set netnsbr3en1 up

# ns6 <--> netnsbr3
ip link add eth0 netns ns6 type veth peer netnsbr3en2
ip netns exec ns6 ip address add 1.1.3.2/24 dev eth0
ip netns exec ns6 ip link set dev eth0 up
ip link set netnsbr3en2 master netnsbr3
ip link set netnsbr3en2 up


# ルーティング
# rt1
ip netns exec rt1 sysctl -w net.ipv4.ip_forward=1 > /dev/null
ip netns exec rt1 ip route add 2.1.2.0/24 via 2.1.1.2 dev en1
ip netns exec rt1 ip route add 1.1.2.0/24 via 2.1.1.2 dev en1
ip netns exec rt1 ip route add 1.1.3.0/24 via 2.1.1.2 dev en1

# rt2
ip netns exec rt2 sysctl -w net.ipv4.ip_forward=1 > /dev/null
ip netns exec rt2 ip route add 1.1.1.0/24 via 2.1.1.1 dev en2
ip netns exec rt2 ip route add 1.1.3.0/24 via 2.1.2.2 dev en1

# rt3
ip netns exec rt3 sysctl -w net.ipv4.ip_forward=1 > /dev/null
ip netns exec rt3 ip route add 2.1.1.0/24 via 2.1.2.1 dev en2
ip netns exec rt3 ip route add 1.1.1.0/24 via 2.1.2.1 dev en2
ip netns exec rt3 ip route add 1.1.2.0/24 via 2.1.2.1 dev en2

# ns
ip netns exec ns1 ip route add default via 1.1.1.254 dev eth0
ip netns exec ns2 ip route add default via 1.1.1.254 dev eth0
ip netns exec ns3 ip route add default via 1.1.2.254 dev eth0
ip netns exec ns4 ip route add default via 1.1.2.254 dev eth0
ip netns exec ns5 ip route add default via 1.1.3.254 dev eth0
ip netns exec ns6 ip route add default via 1.1.3.254 dev eth0


# ホスト名設定
hosts=$(cat << EOF
1.1.1.254   rt1.ns
2.1.1.1     rt1.ns
1.1.2.254   rt2.ns
2.1.1.2     rt2.ns
2.1.2.1     rt2.ns
1.1.3.254   rt3.ns
2.1.2.2     rt3.ns
1.1.1.1     ns1.ns
1.1.1.2     ns2.ns
1.1.2.1     ns3.ns
1.1.2.2     ns4.ns
1.1.3.1     ns5.ns
1.1.3.2     ns6.ns
EOF
)

for i in {1..3}; do
	mkdir /etc/netns/rt${i}
	echo "${hosts}" > /etc/netns/rt${i}/hosts
done
for i in {1..6}; do
	mkdir /etc/netns/ns${i}
	echo "${hosts}" > /etc/netns/ns${i}/hosts
done


#set -x
# 片付け
#ip --all netns delete
#ip link delete netnsbr1
#ip link delete netnsbr2
#ip link delete netnsbr3
#rm -r /etc/netns/*

