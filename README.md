# netns-lab


ネームスペースでネットワーク検証

<p>動作確認 Ubuntu 24.04</p>
<p>RH系もおよそ動きそう</p>

**root権限必要です**
<br>

### 主要ツール

- iproute2
```sh
$ apt info iproute2
Package: iproute2
Version: 6.1.0-1ubuntu6
```

- iptables(nft)
```sh
$ apt info iptables
Package: iptables
Version: 1.8.10-3ubuntu2
```
<br>

### 最もシンプルなネットワーク
<br>

ネームスペース２つ作成
```sh
ip netns add ns1
ip netns add ns2
```

```mermaid
flowchart

%%node
    subgraph HOST[host]
    ns1
    ns2
end

%%connection
ns1 ~~~ ns2
```
<br>

vethペア（仮想LANケーブル）でつなげる
```sh
ip link add veth0 netns ns1 type veth0 peer netns ns2
```

```mermaid
flowchart

%%node
subgraph HOST[host]
    subgraph NS1[ns1]
        ns1-veth0[veth0]
    end
    subgraph NS2[ns2]
        ns2-veth0[veth0]
    end
end

%%connection
ns1-veth0 o--o ns2-veth0
```
<br>

IPアドレスとリンクアップ
```sh
ip netns exec ns1 ip addr add 10.0.0.1/24 dev veth0
ip netns exec ns1 ip link set  veth0 up
ip netns exec ns2 ip addr add 10.0.0.2/24 dev veth0
ip netns exec ns2 ip link set  veth0 up
```

```mermaid
flowchart

%%node
subgraph HOST[host]
    subgraph NS1[ns1]
        ns1-veth0[veth0]
    end
    subgraph NS2[ns2]
        ns2-veth0[veth0]
    end
end

%%connection
ns1-veth0 o--o ns2-veth0

%%style
classDef NIC fill:#da4,color:#35d,stroke:none
class ns1-veth0,ns2-veth0 NIC
```
<br>

接続確認するコマンド例
```sh
ip netns exec ns1 ping -c 3 10.0.0.2
ip netns exec ns1 ip addr  # IPアドレス
ip netns exec ns1 ip link  # インターフェイス
ip netns exec ns1 ip nei   # 隣接するインターフェイス
ip netns exec ns1 ip route # ルーティングテーブル
```
<br>

ネームスペースを削除
```sh
ip netns delete ns1     #個別に削除する場合
ip netns delete ns2
ip --all netns delete   #まとめて全部のnetnsを削除する場合
```

<br>

### Script

**vethペア接続**
- [namespace_ipv4.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/namespace_ipv4.sh)
- [namespace_ipv6.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/namespace_ipv6.sh)
- [host_namespace.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/host_namespace.sh)
- [netns_docker.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/netns_docker.sh)

**ブリッジ接続**
- [bridge.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/bridge.sh)
- [vlan.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/vlan.sh)

**ルーティング**
- [routing.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/routing.sh)
- [line_topology.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/line_topology.sh)
- [nat_masquerade.sh](https://github.com/tomato-tom/netns-lab/blob/main/script/nat_masquerade.sh)


**スクリプトの検索**
```sh
grep -ril <keyword> .
```
keywords:
nat, vlan, route, routing, bridge, subnet, bond, docker

<br>

### nsfunc

一般ユーザで`script`ディレクトリにいる場合
```sh
sudo su
source nsfunc.sh

# ネームスペースのIPアドレス表示
nsinfo               # すべてのネームスペース
nsinfo ns1 ns5 rt3   # 引数でネームスペース指定

# ネームスペースと関連するブリッジ、ファイルを削除
rmns
```

もしくは`/root/.bashrc`等に追記すると便利かもしれません
<br>

### ホストArchlinux

Archlinuxでvethペア作成できない？<br>
デフォルトではモジュール読み込まれないみたい
```sh
# ip link add veth0 type veth peer name veth1
Error: Unknown device type.

# lsmod | grep veth
```

読み込みのファイル作成したらvethペアできた
```
# modprobe -c | grep veth
alias rtnl_link_veth veth

# echo "rtnl_link_veth" > /etc/modules-load.d/rtnl_link_veth.conf
```
[カーネルモジュール ArchWiki](
https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB
)

bondingできない - Archlinux

<br>


### 今後追加してみたいスクリプト

- LXC/LXDとつなげる
- パケットフィルタリング iptables(nft)
- 帯域制限シミュレーション
- 動的ルーティング: **BGP** **RIP** **OSPF**
- トンネリング
- IP v4/v6 over IP v4/v6
- DHCP DNS

> `iptables`は**legacy**らしいけどまだまだ**iptables**いけます！
> そのうちに**nftables**も対応するかも知らません
> [Chapter 10. Getting started with nftables](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/securing_networks/getting-started-with-nftables_securing-networks#when-to-use-firewalld-nftables-or-iptables_assembly_migrating-from-iptables-to-nftables)

<br>


### 参考資料

[Introduction to Linux interfaces for virtual networking](
https://developers.redhat.com/blog/2018/10/22/introduction-to-linux-interfaces-for-virtual-networking#
)
> iproute2の各種インターフェイス、bridge, vlan, vethなど図解とサンプル

<br>

[Network namespaceによるネットワークテスト環境の構築](
https://www.bit-hive.com/articles/20230315
)
> 基本的なネットワーク

<br>

[Network Namespace - CUBE SUGAR CONTAINER](
https://blog.amedama.jp/archive/category/Network%20Namespace#google_vignette
)
> 各種ルーティング、C言語でネームスペース作成とか
> 「Linuxで動かしながら学ぶTCP/IPネットワーク入門」著者の方


<br>

[ネットワーク勉強まとめ](
https://zenn.dev/bells17/scraps/ced3289cd8116d
)
> FRRoutingでOSPFなどなど...

<br>

[Manpages of iproute2 in Debian unstable](
https://manpages.debian.org/unstable/iproute2/index.html
)
- [ip-netns - process network namespace management](https://manpages.debian.org/unstable/iproute2/ip-netns.8.en.html)
- [ip-link - network device configuration](https://manpages.debian.org/unstable/iproute2/ip-link.8.en.html)
- [ip-address - protocol address management](https://manpages.debian.org/unstable/iproute2/ip-address.8.en.html)
- [ip-route - routing table management](https://manpages.debian.org/unstable/iproute2/ip-route.8.en.html)
- [ip-neighbour - neighbour/arp tables management.](https://manpages.debian.org/unstable/iproute2/ip-neighbour.8.en.html)
- [bridge - show / manipulate bridge addresses and devices](https://manpages.debian.org/unstable/iproute2/bridge.8.en.html)
