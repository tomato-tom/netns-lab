#!/bin/bash -e


# RT0 [en0] -----> [balckhole]
#       |.2
#       |
#       |10.0.0.0/24
#       |
#       |.1                                   192.168.1.0/24
#     [en0]  .254              .253   .254                                 .1
# RT1 [en1] ------------------- L3BR0[br0]------ [en0] L2BR0 [en1] --------- [eth0] NS10
#     [en2]    192.168.0.0/16    .254 |                      [en2]|
#       |                             |                           |        .2
#     .2|                             |                           |--------- [eth0] NS09
#       |                             |   192.168.2.0/24
#       |                             |                                    .1
#       |10.0.1.0/24                  |--------- [en0] L2BR1 [en1] --------- [eth0] NS08
#       |                                                    [en2]|
#       |                                                         |        .2
#       |                                                         |--------- [eth0] NS07
#     .1|                                    192.169.1.0/24
#     [en0]   .254           .253    .254                                  .1
# RT2 [en1] ----------------- L3BR1 [br0] ------ [en0] L2BR2 [en1] --------- [eth0] NS06
#     [en2]   192.169.0.0/16     .254 |                      [en2]|
#       |                             |                           |        .2             
#     .2|                             |                           |--------- [eth0] NS05
#       |                             |                                                 
#       |                             |      192.169.2.0/24                  .1                                           
#       |10.0.2.0/24                  |--------- [en0] L2BR3 [en1] --------- [eth0] NS04
#       |                                                    [en2]|                     
#       |                                                         |        .2             
#       |                                                         |--------- [eth0] NS03
#     .1|
#     [en0]                 192.170.0.0/24                     .1
# RT3 [en1] ----------------------- [en0] L2BR4 [en1] --------- [eth0] NS02
#     [en2]   .254                              [en2]|
#       |                                            |          .2           
#     .254                                           |--------- [eth0] NS01
#       |
#       |10.0.3.0/24
#       |
#       |
#       |.1
# NS00[eth0]


# RT -----------------------------------------------
ip netns add RT0
ip netns add RT1
ip netns add RT2
ip netns add RT3
ip netns exec RT0 ip link set lo up
ip netns exec RT1 ip link set lo up
ip netns exec RT2 ip link set lo up
ip netns exec RT3 ip link set lo up

# RT0 <---> RT1
ip link add en0 netns RT0 type veth peer en0 netns RT1
ip netns exec RT0 ip addr add 10.0.0.2/24 dev en0
ip netns exec RT0 ip link set en0 up
ip netns exec RT1 ip addr add 10.0.0.1/24 dev en0
ip netns exec RT1 ip link set en0 up

# RT1 <---> RT2
ip link add en2 netns RT1 type veth peer en0 netns RT2
ip netns exec RT1 ip addr add 10.0.1.2/24 dev en2
ip netns exec RT1 ip link set en2 up
ip netns exec RT2 ip addr add 10.0.1.1/24 dev en0
ip netns exec RT2 ip link set en0 up

# RT2 <---> RT3
ip link add en2 netns RT2 type veth peer en0 netns RT3
ip netns exec RT2 ip addr add 10.0.2.2/24 dev en2
ip netns exec RT2 ip link set en2 up
ip netns exec RT3 ip addr add 10.0.2.1/24 dev en0
ip netns exec RT3 ip link set en0 up

# L3BR --------------------------------------------------
ip netns add L3BR0
ip netns exec L3BR0 ip link set lo up
ip netns exec L3BR0 ip link add br0 type bridge
ip netns exec L3BR0 ip link set br0 up
ip netns add L3BR1
ip netns exec L3BR1 ip link set lo up
ip netns exec L3BR1 ip link add br0 type bridge
ip netns exec L3BR1 ip link set br0 up

# RT1 <---> L3BR0
ip link add en1 netns RT1 type veth peer en0 netns L3BR0
ip netns exec RT1 ip addr add 192.168.0.254/16 dev en1
ip netns exec RT1 ip link set en1 up
ip netns exec L3BR0 ip addr add 192.168.0.253/16 dev br0
ip netns exec L3BR0 ip link set en0 master br0
ip netns exec L3BR0 ip link set en0 up


# RT2 <---> L3BR1
ip link add en1 netns RT2 type veth peer en0 netns L3BR1
ip netns exec RT2 ip addr add 192.169.0.254/16 dev en1
ip netns exec RT2 ip link set en1 up
ip netns exec L3BR1 ip addr add 192.169.0.253/16 dev br0
ip netns exec L3BR1 ip link set en0 master br0
ip netns exec L3BR1 ip link set en0 up


# L2BR -----------------------------------------
ip netns add L2BR0
ip netns exec L2BR0 ip link set lo up
ip netns exec L2BR0 ip link add br0 type bridge
ip netns exec L2BR0 ip link set br0 up
ip netns add L2BR1
ip netns exec L2BR1 ip link set lo up
ip netns exec L2BR1 ip link add br0 type bridge
ip netns exec L2BR1 ip link set br0 up
ip netns add L2BR2
ip netns exec L2BR2 ip link set lo up
ip netns exec L2BR2 ip link add br0 type bridge
ip netns exec L2BR2 ip link set br0 up
ip netns add L2BR3
ip netns exec L2BR3 ip link set lo up
ip netns exec L2BR3 ip link add br0 type bridge
ip netns exec L2BR3 ip link set br0 up
ip netns add L2BR4
ip netns exec L2BR4 ip link set lo up
ip netns exec L2BR4 ip link add br0 type bridge
ip netns exec L2BR4 ip link set br0 up


# L3BR0 <---> L2BR0
ip link add en1 netns L3BR0 type veth peer en0 netns L2BR0
ip netns exec L3BR0 ip addr add 192.168.1.254/24 dev br0
ip netns exec L3BR0 ip link set en1 master br0
ip netns exec L3BR0 ip link set en1 up
ip netns exec L2BR0 ip link set en0 master br0
ip netns exec L2BR0 ip link set en0 up

# L3BR0 <---> L2BR1
ip link add en2 netns L3BR0 type veth peer en0 netns L2BR1
ip netns exec L3BR0 ip addr add 192.168.2.254/24 dev br0
ip netns exec L3BR0 ip link set en2 master br0
ip netns exec L3BR0 ip link set en2 up
ip netns exec L2BR1 ip link set en0 master br0
ip netns exec L2BR1 ip link set en0 up

# L3BR1 <---> L2BR2
ip link add en1 netns L3BR1 type veth peer en0 netns L2BR2
ip netns exec L3BR1 ip addr add 192.169.1.254/24 dev br0
ip netns exec L3BR1 ip link set en1 master br0
ip netns exec L3BR1 ip link set en1 up
ip netns exec L2BR2 ip link set en0 master br0
ip netns exec L2BR2 ip link set en0 up

# L3BR1 <---> L2BR3
ip link add en2 netns L3BR1 type veth peer en0 netns L2BR3
ip netns exec L3BR1 ip addr add 192.169.2.254/24 dev br0
ip netns exec L3BR1 ip link set en2 master br0
ip netns exec L3BR1 ip link set en2 up
ip netns exec L2BR3 ip link set en0 master br0
ip netns exec L2BR3 ip link set en0 up

# RT3 <---> L2BR4
ip link add en1 netns RT3 type veth peer en0 netns L2BR4
ip netns exec RT3 ip addr add 192.170.0.254/24 dev en1
ip netns exec RT3 ip link set en1 up
ip netns exec L2BR4 ip link set en0 master br0
ip netns exec L2BR4 ip link set en0 up


# NS -------------------------------------------------

# create namespaces
for i in {00..10}; do
    ip netns add NS${i}
    ip netns exec NS${i} ip link set lo up
done

# NS00 <---> RT3
ip link add eth0 netns NS00 type veth peer en2 netns RT3
ip netns exec NS00 ip addr add 10.0.3.1/24 dev eth0
ip netns exec NS00 ip link set eth0 up
ip netns exec RT3 ip addr add 10.0.3.254/24 dev en2
ip netns exec RT3 ip link set en2 up

# NS01 <---> L2BR4
ip link add eth0 netns NS01 type veth peer en2 netns L2BR4
ip netns exec NS01 ip addr add 192.170.0.2/24 dev eth0
ip netns exec NS01 ip link set eth0 up
ip netns exec L2BR4 ip link set en2 master br0
ip netns exec L2BR4 ip link set en2 up

# NS02 <---> L2BR4
ip link add eth0 netns NS02 type veth peer en1 netns L2BR4
ip netns exec NS02 ip addr add 192.170.0.1/24 dev eth0
ip netns exec NS02 ip link set eth0 up
ip netns exec L2BR4 ip link set en1 master br0
ip netns exec L2BR4 ip link set en1 up

# NS03 <---> L2BR3
ip link add eth0 netns NS03 type veth peer en2 netns L2BR3
ip netns exec NS03 ip addr add 192.169.2.2/24 dev eth0
ip netns exec NS03 ip link set eth0 up
ip netns exec L2BR3 ip link set en2 master br0
ip netns exec L2BR3 ip link set en2 up

# NS04 <---> L2BR3
ip link add eth0 netns NS04 type veth peer en1 netns L2BR3
ip netns exec NS04 ip addr add 192.169.2.1/24 dev eth0
ip netns exec NS04 ip link set eth0 up
ip netns exec L2BR3 ip link set en1 master br0
ip netns exec L2BR3 ip link set en1 up

# NS05 <---> L2BR2
ip link add eth0 netns NS05 type veth peer en2 netns L2BR2
ip netns exec NS05 ip addr add 192.169.1.2/24 dev eth0
ip netns exec NS05 ip link set eth0 up
ip netns exec L2BR2 ip link set en2 master br0
ip netns exec L2BR2 ip link set en2 up

# NS06 <---> L2BR2
ip link add eth0 netns NS06 type veth peer en1 netns L2BR2
ip netns exec NS06 ip addr add 192.169.1.1/24 dev eth0
ip netns exec NS06 ip link set eth0 up
ip netns exec L2BR2 ip link set en1 master br0
ip netns exec L2BR2 ip link set en1 up

# NS07 <---> L2BR1
ip link add eth0 netns NS07 type veth peer en2 netns L2BR1
ip netns exec NS07 ip addr add 192.168.2.2/24 dev eth0
ip netns exec NS07 ip link set eth0 up
ip netns exec L2BR1 ip link set en2 master br0
ip netns exec L2BR1 ip link set en2 up

# NS08 <---> L2BR1
ip link add eth0 netns NS08 type veth peer en1 netns L2BR1
ip netns exec NS08 ip addr add 192.168.2.1/24 dev eth0
ip netns exec NS08 ip link set eth0 up
ip netns exec L2BR1 ip link set en1 master br0
ip netns exec L2BR1 ip link set en1 up

# NS09 <---> L2BR0
ip link add eth0 netns NS09 type veth peer en2 netns L2BR0
ip netns exec NS09 ip addr add 192.168.1.2/24 dev eth0
ip netns exec NS09 ip link set eth0 up
ip netns exec L2BR0 ip link set en2 master br0
ip netns exec L2BR0 ip link set en2 up

# NS10 <---> L2BR0
ip link add eth0 netns NS10 type veth peer en1 netns L2BR0
ip netns exec NS10 ip addr add 192.168.1.1/24 dev eth0
ip netns exec NS10 ip link set eth0 up
ip netns exec L2BR0 ip link set en1 master br0
ip netns exec L2BR0 ip link set en1 up


# routing
ip netns exec RT0 ip route add blackhole default
ip netns exec RT1 sysctl net.ipv4.ip_forward=1 > /dev/null
ip netns exec RT1 ip route add 10.0.2.0/24 via 10.0.1.1 dev en2
ip netns exec RT1 ip route add 10.0.3.0/24 via 10.0.1.1 dev en2
ip netns exec RT1 ip route add 192.169.0.0/16 via 10.0.1.1 dev en2
ip netns exec RT1 ip route add 192.170.0.0/24 via 10.0.1.1 dev en2
ip netns exec RT2 sysctl net.ipv4.ip_forward=1 > /dev/null
ip netns exec RT2 ip route add 10.0.0.0/24 via 10.0.1.2 dev en0
ip netns exec RT2 ip route add 192.168.0.0/16 via 10.0.1.2 dev en0
ip netns exec RT2 ip route add 10.0.3.0/24 via 10.0.2.1 dev en2
ip netns exec RT2 ip route add 192.170.0.0/24 via 10.0.2.1 dev en2
ip netns exec RT3 sysctl net.ipv4.ip_forward=1 > /dev/null
ip netns exec RT3 ip route add 10.0.1.0/24 via 10.0.2.2 dev en0
ip netns exec RT3 ip route add 10.0.0.0/24 via 10.0.2.2 dev en0
ip netns exec RT3 ip route add 192.168.0.0/16 via 10.0.2.2 dev en0
ip netns exec RT3 ip route add 192.169.0.0/16 via 10.0.2.2 dev en0
ip netns exec L3BR0 ip route add default via 192.168.0.254 dev br0
ip netns exec L3BR1 ip route add default via 192.169.0.254 dev br0


ip netns exec NS00 ip route add default via 10.0.3.254 dev eth0
ip netns exec NS01 ip route add default via 192.170.0.254 dev eth0
ip netns exec NS02 ip route add default via 192.170.0.254 dev eth0
ip netns exec NS03 ip route add default via 192.169.2.254 dev eth0
ip netns exec NS04 ip route add default via 192.169.2.254 dev eth0
ip netns exec NS05 ip route add default via 192.169.1.254 dev eth0
ip netns exec NS06 ip route add default via 192.169.1.254 dev eth0
ip netns exec NS07 ip route add default via 192.168.2.254 dev eth0
ip netns exec NS08 ip route add default via 192.168.2.254 dev eth0
ip netns exec NS09 ip route add default via 192.168.1.254 dev eth0
ip netns exec NS10 ip route add default via 192.168.1.254 dev eth0


#ip --all delete
