#!/bin/bash


# ネームスペース情報
# 引数でネームスペース名指定、引数無しですべてのネームスペース情報
nsinfo () {
    allns=$(ip netns | sed 's/ (id: [0-9]\+)//g')
    if [ $# -eq 0 ]; then
        nodes=$allns
    else
        nodes=$@
    fi
    for node in $nodes; do
        if echo "$allns" | grep -q "$node"; then
            echo -n "$node "
            ip netns exec $node hostname -I
        else
            echo "ネームスペース $node は存在しません"
        fi
    done
}


# 片付け
rmns() {
    # すべてのネットワークネームスペースの削除
    ip --all netns delete

    # 名前がnetnsbr*のブリッジの削除 
    interfaces=$(ip link | grep -o 'netnsbr[0-9]*' | uniq)
    for i in $interfaces; do
        ip link delete $i
    done

    # netns用のディレクトリの削除
    rm -rf /etc/netns/*
}

