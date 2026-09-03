# review-commits

base commitとtarget commitの差分をdifitで表示し、人間が入力したレビューコメントを取得する[^difit]。

## 入力

- repositoryのpath
- base commit
- target commit

## 出力

- レビュー対象
- 人間のレビューコメント

## 制約

- base commitとtarget commitを省略しない。
- target commitが現在のbranchのHEADと一致する状態で実行する。
- commitしていない変更がある場合は実行しない。
- `--keep-alive`と`--no-open`を使わない。
- difitを自動で終了しない。

## 手順

### 1. レビュー対象へ移動する

repositoryのpathを作業ディレクトリにする。

### 2. difitを起動する

```sh
difit <target-commit> <base-commit> --clean
```

表示されたURLとレビュー対象を記録する。

### 3. 人間のレビューを待つ

人間がブラウザで差分を確認し、必要なコメントを入力してブラウザを閉じるまで待つ。

### 4. コメントを取得する

difitが終了した後、標準出力に表示されたレビューコメントを取得する。
コメントが表示されなかった場合は、修正を求めるコメントがなかったことを記録する。

### 5. 結果を返す

repository、base commit、target commit、レビューコメントを返す。
difitが正常に終了しなかった場合は、レビューが完了していないことを返す。

[^difit]: [difit README](https://github.com/yoshiko-pg/difit/blob/main/README.ja.md)
