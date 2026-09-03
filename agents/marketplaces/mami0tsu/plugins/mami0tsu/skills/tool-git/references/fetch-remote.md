# fetch-remote

指定したremoteのdefault branchを確認し、remote-tracking branchを更新する[^git-fetch]。

## 入力

- repositoryのpath
- remote

## 出力

- remote URL
- default branch
- fetch結果

## 制約

- remoteとdefault branchを名前から推測しない。
- credentialとremote URLを変更しない。

## 手順

### 1. Remoteを確認する

```sh
git -C <repository-path> remote get-url <remote>
git -C <repository-path> ls-remote --symref <remote> HEAD
```

### 2. Remoteをfetchする

```sh
git -C <repository-path> fetch <remote>
```

### 3. 結果を取得する

```sh
git -C <repository-path> status --porcelain=v1 --branch
```

### 4. 結果を返す

remote URL、`refs/heads/`のシンボリック参照（symref）が示すdefault branch、fetch結果、statusを返す。

[^git-fetch]: [Git `fetch` manual](https://git-scm.com/docs/git-fetch)
