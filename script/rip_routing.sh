#!/bin/bash

# birdでRIP
# ns1 <--> rt1 <--> rt2 <--> ns2

# create namespace
ip netns add ns1
ip netns add ns2
ip netns add rt1
ip netns add rt2

# ns1 <-> rt1
ip link add veth0 netns ns1 type veth peer veth0 netns rt1
ip netns exec ns1 ip addr add 10.0.0.1/24 dev veth0
ip netns exec ns1 ip link set veth0 up
ip netns exec rt1 ip addr add 10.0.0.254/24 dev veth0
ip netns exec rt1 ip link set veth0 up

# rt1 <-> rt2
ip link add veth1 netns rt1 type veth peer veth0 netns rt2
ip netns exec rt1 ip addr add 192.168.1.1/24 dev veth1
ip netns exec rt1 ip link set veth1 up
ip netns exec rt1 sysctl -w -q net.ipv4.ip_forward=1
ip netns exec rt2 ip addr add 192.168.1.2/24 dev veth0
ip netns exec rt2 ip link set veth0 up
ip netns exec rt2 sysctl -w -q net.ipv4.ip_forward=1

# rt2 <-> ns2
ip link add veth1 netns rt2 type veth peer veth0 netns ns2
ip netns exec rt2 ip addr add 10.0.1.254/24 dev veth1
ip netns exec rt2 ip link set veth1 up
ip netns exec ns2 ip addr add 10.0.1.1/24 dev veth0
ip netns exec ns2 ip link set veth0 up

# routing
ip netns exec ns1 ip route add default via 10.0.0.254 dev veth0
ip netns exec ns2 ip route add default via 10.0.1.254 dev veth0

# RIP
mkdir -p /etc/bird
mkdir -p /etc/netns/rt1/bird
mkdir -p /etc/netns/rt2/bird

echo birdの設定ファイルを作成します
cat << EOF > /etc/netns/rt1/bird/rt1.conf
log syslog all;
log stderr all;
log "/etc/bird/rt1.log" all;
debug protocols all;

protocol device {
}

protocol direct {
    ipv4;
}

protocol rip {
    ipv4 {
        import all;
        export all;
    };
    interface "veth1" {
        update time 10;
        timeout time 60;  # タイムアウト間隔を60秒に設定 (デフォルトは180秒)
    };
}

protocol kernel {
    ipv4 {
        export all;
    };
}
EOF

cat << EOF > /etc/netns/rt2/bird/rt2.conf
log syslog all;
log stderr all;
log "/etc/bird/rt2.log" all;
debug protocols all;

protocol device {
}

protocol direct {
    ipv4;
}

protocol rip {
    ipv4 {
        import all;
        export all;
    };
    interface "veth0" {
        update time 10;
        timeout time 60;
    };
}
protocol kernel {
    ipv4 {
        export all;
    };
}
EOF

echo birdを起動します
ip netns exec rt1 bird -c /etc/bird/rt1.conf -s /etc/bird/rt1.ctl -P /etc/bird/rt1.pid
ip netns exec rt2 bird -c /etc/bird/rt2.conf -s /etc/bird/rt2.ctl -P /etc/bird/rt2.pid

sleep 1
echo 'ns1 -> ns2 ping'
ip netns exec ns1 ping -c 3 -R 10.0.1.1

# 後片付けを実行するかどうかを確認
read -p "後片付けをしますか？ (y/n): " choice

if [[ "$choice" == [Yy] ]]; then
    echo 後片付け中...
    ip netns exec rt1 birdc -s /etc/bird/rt1.ctl down
    ip netns exec rt2 birdc -s /etc/bird/rt2.ctl down
    ip --all netns del
    rm -rf /etc/netns/*
    echo "後片付けが完了しました。"
else
    echo "後片付けはroot権限で以下のコマンドを実行してください。"
    echo 'ip netns exec rt1 birdc -s /etc/bird/rt1.ctl down'
    echo 'ip netns exec rt2 birdc -s /etc/bird/rt2.ctl down'
    echo 'ip --all netns del'
    echo 'rm -rf /etc/netns/*'
fi

