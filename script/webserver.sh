#!/bin/bash

set -e

# ネットワークネームスペースの作成
ip netns add server
ip netns add client

# 仮想インターフェースの作成と設定
ip link add veth0 type veth peer name veth1
ip link set veth0 netns server
ip link set veth1 netns client

ip netns exec server ip addr add 10.0.0.1/24 dev veth0
ip netns exec server ip link set veth0 up

ip netns exec client ip addr add 10.0.0.2/24 dev veth1
ip netns exec client ip link set veth1 up

# ネットワークネームスペース固有のディレクトリ作成
mkdir /etc/www
mkdir -p /etc/netns/server/www

# /etc/wwwがマウントされるまで待機
ip netns exec server sh -c 'while [ ! -d /etc/www ]; do sleep 0.1; done'

# ネームスペース内での操作
ip netns exec server sh -c 'echo "<h1>Hello Python HTTP Server</h1>" > /etc/www/index.html'

echo サーバーを起動します...
ip netns exec server sh -c 'cd /etc/www && python3 -m http.server 8080 &'

# サーバーが起動するまで待機（最大3秒間）
timeout=3
interval=0.1
elapsed=0

until ip netns exec client curl -s --head http://10.0.0.1:8080 | grep "200 OK" > /dev/null; do
    sleep $interval
    elapsed=$(echo "$elapsed + $interval" | bc)
    #echo $elapsed

    if (( $(echo "$elapsed >= $timeout" | bc -l) )); then
        echo "Timeout: サーバーが起動しませんでした。"
        break
    fi
done

echo サーバーにリクエスト送信します...
ip netns exec client curl http://10.0.0.1:8080

# サーバーの停止とクリーンアップ
sleep 1
kill $(pgrep -f "http.server")
ip --all netns delete
rm -rf /etc/netns/server
rm -rf /etc/www

