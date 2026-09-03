# push-branch

指定したlocal branchをremote branchへpushする[^git-push]。

## 入力

- repositoryのpath
- remote
- local branch
- remote branch
- `inspect-push`ユースケースの成功結果

## 出力

- push結果
- upstream
- remote branchのcommit

## 制約

- `inspect-push`と同じremote、local branch、remote branchを使う。
- force pushのoptionを使わない。
- local branchのHEADを`inspect-push`の実行後に変更しない。

## 手順

### 1. Branchをpushする

```sh
git -C <repository-path> push --porcelain --set-upstream <remote> <local-branch>:refs/heads/<remote-branch>
```

### 2. Push結果を取得する

```sh
git -C <repository-path> status --porcelain=v1 --branch
git -C <repository-path> ls-remote --heads <remote> refs/heads/<remote-branch>
```

### 3. 結果を返す

push結果、upstream、remote branchのcommitを返す。

[^git-push]: [Git `push` manual](https://git-scm.com/docs/git-push)
