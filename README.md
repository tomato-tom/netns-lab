# netns-lab

ネームスペースでネットワーク検証<br>
root権限必要です

動作確認 Ubuntu 24.04<br>
[script](
https://github.com/tomato-tom/netns-lab/tree/main/script
)

### 主要ツール

- iproute2
- iptables(nft)

### Script

- namespace_ipv4.sh
- namespace_ipv6.sh
- host_namespace.sh
- routing.sh
- bridge.sh
- vlan.sh
- nat_masquerade.sh
- netns_docker.sh
- line_topology.sh


### vethペア作成できない？

Archlinuxでvethペア作成できない？<br>
デフォルトではモジュール読み込まれないみたい
```sh
# ip link add veth0 type veth peer name veth1
Error: Unknown device type.

# lsmod | grep veth
```

```
# modprobe -c | grep veth
alias rtnl_link_veth veth

# echo "rtnl_link_veth" /etc/modules-load.d/rtnl_link_veth.conf
```
[カーネルモジュール](
https://wiki.archlinux.jp/index.php/%E3%82%AB%E3%83%BC%E3%83%8D%E3%83%AB%E3%83%A2%E3%82%B8%E3%83%A5%E3%83%BC%E3%83%AB
)
