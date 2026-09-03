# inspect-remote-branch

指定したremote branchが存在するか確認する[^git-ls-remote]。

## 入力

- repositoryのpath
- remote
- remote branch

## 出力

- remote URL
- remote branchのcommit

## 制約

- remote branchを作成、更新、削除しない。
- remote tracking branchを確認結果として使わない。
- credentialとremote URLを変更しない。

## 手順

### 1. Remoteを確認する

```sh
git -C <repository-path> remote get-url <remote>
```

### 2. Remote branchを確認する

```sh
git -C <repository-path> ls-remote --heads <remote> refs/heads/<remote-branch>
```

### 3. 結果を返す

remote URLとremote branchのcommitを返す。
出力が空の場合は、remote branchが存在しないことを返す。

[^git-ls-remote]: [Git `ls-remote` manual](https://git-scm.com/docs/git-ls-remote)
