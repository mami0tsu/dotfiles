---
name: d2-diagram
description: D2 の宣言的な記法で構成図やフロー図を作成し、ソースと SVG を出力する。D2 形式の図を新規作成、編集、描画するときに使う。
---

# D2 Diagram

図の編集可能性を保つため、D2 ソースを成果物に含める。

## 手順

1. 図の要素と関係を整理し、`<name>.d2` に記述する。
2. `d2 <name>.d2 <name>.svg` で SVG を生成する。
3. SVG を確認し、重なり、欠落、読みにくいラベルを修正する。
4. `.d2` と `.svg` を成果物として残す。

PNG または PDF はユーザーが指定した場合だけ生成する。

## 実行

```sh
d2 input.d2 output.svg
```

編集しながら確認する場合は watch mode を使う。

```sh
d2 --watch input.d2 output.svg
```
