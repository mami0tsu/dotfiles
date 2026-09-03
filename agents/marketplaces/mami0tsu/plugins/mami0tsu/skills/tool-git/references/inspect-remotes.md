# inspect-remotes

指定したrepositoryに設定されたremoteとURLを取得する[^git-remote]。

## 入力

- repositoryのpath

## 出力

- remoteの名前
- fetch URL
- push URL

## 制約

- remoteを追加、変更、削除しない。
- credentialを表示しない。
- remoteの名前を推測しない。

## 手順

### 1. Remoteを取得する

```sh
git -C <repository-path> remote
```

### 2. URLを取得する

取得した各remoteについて実行する。

```sh
git -C <repository-path> remote get-url <remote>
git -C <repository-path> remote get-url --push <remote>
```

URLにcredentialが含まれている場合は、credentialを除いたURLだけを返す。

### 3. 結果を返す

remoteの名前、fetch URL、push URLを返す。

[^git-remote]: [Git `remote` manual](https://git-scm.com/docs/git-remote)
