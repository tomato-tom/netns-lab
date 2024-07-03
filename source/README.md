# nsup.py

python実行ファイルからyaml設定ファイル読み込んでネットワーク構築します

デフォルトの`config/config.yaml`で実行する場合
```sh
sudo python3 nsup.py
```

yamlファイルを引数で指定し読み込んで実行する場合の例
```sh
sudo python3 nsup.py config/ns1_ns2.yaml
```

- ネームスペース作成
- vethペア接続
- bridge接続
- 静的IPアドレス
- 静的ルート
- カスタムコマンド

