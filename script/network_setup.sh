#!/bin/bash

PROJECT_ROOT="$(cd $(dirname "${BASH_SOURCE[0]}")/../ && pwd)"
CONFIG_FILE="$PROJECT_ROOT/config/config.json"

set -e

# 設定ファイルを解析する関数
parse_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Config file $CONFIG_FILE not found"
        exit 1
    fi
    
    if ! jq empty "$CONFIG_FILE" 2>/dev/null; then
        echo "Error: Invalid JSON in config file"
        exit 1
    fi
}

# より確実にユニークなMACアドレスを生成する関数
generate_mac() {
    # /dev/urandomを使用してより確実にランダムな値を生成
    printf '02:%02x:%02x:%02x:%02x:%02x\n' \
        $(od -An -N1 -tu1 < /dev/urandom) \
        $(od -An -N1 -tu1 < /dev/urandom) \
        $(od -An -N1 -tu1 < /dev/urandom) \
        $(od -An -N1 -tu1 < /dev/urandom) \
        $(od -An -N1 -tu1 < /dev/urandom)
}
# 同時刻にmacアドレスを自動生成すると同じアドレスになるため

# ブリッジを作成する関数
create_bridge() {
    local bridge_name="$1"
    echo "Creating bridge: $bridge_name"
    
    # ブリッジが既に存在するかチェック
    if ip link show "$bridge_name" >/dev/null 2>&1; then
        echo "Bridge $bridge_name already exists, deleting..."
        ip link delete "$bridge_name" 2>/dev/null || true
    fi
    
    ip link add name "$bridge_name" type bridge
    ip link set "$bridge_name" up
    
    # ブリッジの初期化を待つ
    sleep 0.5
}

# vethペアを作成し、ブリッジに接続する関数
connect_veth() {
    local veth_host="$1"
    local veth_peer="$2"
    local netns="$3"
    local bridge="$4"
    
    echo "Creating veth pair: $veth_host <-> $veth_peer"
    
    # 既存のvethペアを削除
    ip link delete "$veth_host" 2>/dev/null || true
    
    # vethペアを作成
    ip link add "$veth_host" type veth peer name "$veth_peer"
    
    # MACアドレスを設定（重複を避けるため）
    local host_mac=$(generate_mac)
    local peer_mac=$(generate_mac)
    
    ip link set dev "$veth_host" address "$host_mac"
    ip link set dev "$veth_peer" address "$peer_mac"
    
    echo "  Host side MAC: $host_mac, Peer side MAC: $peer_mac"
    
    # peer側をnetnsに移動する前にIPv6を無効化
    echo 1 > /proc/sys/net/ipv6/conf/"$veth_peer"/disable_ipv6 2>/dev/null || true
    
    # peer側をnetnsに移動
    ip link set "$veth_peer" netns "$netns"
    
    # host側をブリッジに接続する前にリンクアップ
    ip link set "$veth_host" up
    sleep 0.2
    
    # host側をブリッジに接続
    ip link set "$veth_host" master "$bridge"
    sleep 0.2
    
    # netns内でpeer側のIPv6を無効化してからリンクアップ
    ip netns exec "$netns" bash -c "echo 1 > /proc/sys/net/ipv6/conf/$veth_peer/disable_ipv6 2>/dev/null || true"
    ip netns exec "$netns" ip link set "$veth_peer" up
    
    # リンクの安定化を待つ
    sleep 0.5
}

# ネットワーク名前空間を作成する関数
create_netns() {
    local netns_name="$1"
    echo "Creating network namespace: $netns_name"
    
    # 既存の名前空間を削除
    ip netns delete "$netns_name" 2>/dev/null || true
    
    # 新しい名前空間を作成
    ip netns add "$netns_name"
    
    # loopbackインターフェースを有効化
    ip netns exec "$netns_name" ip link set lo up
    
    sleep 0.1
}

# IPアドレスを設定する関数
ip_address() {
    local netns="$1"
    local interface="$2"
    local ip_addr="$3"
    
    echo "Setting IP address $ip_addr on $interface in $netns"
    
    if [[ "$netns" == "host" ]]; then
        ip addr add "$ip_addr" dev "$interface"
    else
        ip netns exec "$netns" ip addr add "$ip_addr" dev "$interface"
    fi
    
    # IPアドレス設定の安定化を待つ
    sleep 0.2
}

# 接続確認する関数
check_connection() {
    echo "Checking connectivity..."
    
    # ARPテーブルをクリア
    ip netns exec ns1 ip neigh flush all 2>/dev/null || true
    ip netns exec ns2 ip neigh flush all 2>/dev/null || true
    
    sleep 1
    
    # ns1からns2へのping
    echo "Pinging from ns1 (10.1.1.101) to ns2 (10.1.1.102)..."
    if ip netns exec ns1 ping -c 3 -W 2 10.1.1.102; then
        echo "SUCCESS: ns1 -> ns2 ping successful!"
    else
        echo "FAILED: ns1 -> ns2 ping failed"
        return 1
    fi
    
    # ns2からns1へのping
    echo "Pinging from ns2 (10.1.1.102) to ns1 (10.1.1.101)..."
    if ip netns exec ns2 ping -c 3 -W 2 10.1.1.101; then
        echo -e "SUCCESS: ns2 -> ns1 ping successful!\n"
    else
        echo "FAILED: ns2 -> ns1 ping failed"
        return 1
    fi
}

# デバッグ情報を表示する関数
debug_info() {
    echo "=== Debug Information ==="
    
    echo "Bridge status:"
    ip link show ns-br0
    bridge link show
    
    echo -e "\nNamespace ns1 interfaces:"
    ip netns exec ns1 ip addr show
    
    echo -e "\nNamespace ns2 interfaces:"
    ip netns exec ns2 ip addr show
    
    echo -e "\nARP tables:"
    echo "ns1:"
    ip netns exec ns1 ip neigh show 2>/dev/null || echo "No ARP entries"
    echo "ns2:"
    ip netns exec ns2 ip neigh show 2>/dev/null || echo "No ARP entries"
}

# クリーンアップ関数
cleanup() {
    echo "Cleaning up existing configuration..."
    
    # ネットワーク名前空間を削除
    ip netns delete ns1 2>/dev/null || true
    ip netns delete ns2 2>/dev/null || true
    
    # vethペアを削除（ブリッジから自動的に切断される）
    ip link delete ve-ns1 2>/dev/null || true
    ip link delete ve-ns2 2>/dev/null || true
    
    # ブリッジを削除
    ip link delete ns-br0 2>/dev/null || true
    
    sleep 0.5
}

# メイン処理
main() {
    local command="${1:-build}"
    
    case "$command" in
        "build")
            echo "Starting network setup..."
            
            # 設定ファイルを解析
            parse_config
            
            # 既存設定をクリーンアップ
            cleanup
            
            # ネットワーク名前空間を作成
            jq -r '.netns[].name' "$CONFIG_FILE" | while read -r netns; do
                create_netns "$netns"
            done
            
            # ブリッジを作成
            jq -r '.host.links[] | select(.type == "bridge") | .name' "$CONFIG_FILE" | while read -r bridge; do
                create_bridge "$bridge"
            done
            
            # vethペアを作成してブリッジに接続
            jq -r '.host.links[] | select(.type == "veth") | "\(.name) \(.peer.name) \(.peer.netns) \(.master)"' "$CONFIG_FILE" | while read -r veth_host veth_peer netns bridge; do
                connect_veth "$veth_host" "$veth_peer" "$netns" "$bridge"
            done
            
            # IPアドレスを設定
            jq -r '.netns[] as $ns | $ns.links[] as $link | $link.ip_addresses[] as $ip | "\($ns.name) \($link.name) \($ip)"' "$CONFIG_FILE" | while read -r netns interface ip_addr; do
                ip_address "$netns" "$interface" "$ip_addr"
            done
            
            # ネットワークの安定化を待つ
            echo "Waiting for network to stabilize..."
            sleep 3
            
            # 接続確認
            if check_connection; then
                echo "Network setup completed successfully!"
            else
                exit 1
            fi
            ;;
        "debug")
            debug_info
            ;;
        "cleanup")
            cleanup
            ;;
        *)
            echo "Usage: $0 {build|debug|cleanup}"
            exit 1
            ;;
    esac
}

# スクリプトが直接実行された場合
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
