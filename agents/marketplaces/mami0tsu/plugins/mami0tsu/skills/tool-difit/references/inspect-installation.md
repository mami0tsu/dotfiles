# inspect-installation

difitの実行ファイルが存在することを確認する[^difit]。

## 入力

- なし

## 出力

- difitの実行ファイル

## 制約

- difitをインストールまたは更新しない。
- `npx difit`を実行しない。

## 手順

### 1. 実行ファイルを確認する

```sh
command -v difit
```

実行ファイルが見つからない場合は停止する。

### 2. 結果を返す

実行ファイルのpathを返す。

[^difit]: [difit README](https://github.com/yoshiko-pg/difit/blob/main/README.ja.md)
