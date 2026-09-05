# read-file-at-commit

## 情報源

- 公式ドキュメント：[Git `show` manual](https://git-scm.com/docs/git-show)
- 検証バージョン：`git version 2.55.0`
- 確認コマンド：`git --version`、`git show -h`

## 目的

指定commitにある1つのfileから、本文とraw blob SHA-256を取得する。

## 前提条件

- repository path
- 完全なcommit OID
- repository rootからのfile path

## 推奨コマンド

本文を取得する。

```sh
git -C <repository-path> show <commit-oid>:<file-path>
```

同じblobのbyte列を照合するためのraw blob SHA-256を取得する。

```sh
git -C <repository-path> show <commit-oid>:<file-path> | shasum -a 256
```

## 結果の確認

本文を取得したobjectとraw blob SHA-256を求めたobjectへ、同じ完全なcommit OIDとfile pathを指定したことを確認する。
この値を改行正規化済みの`design_body_digest`として使わない。

## 停止条件

commit、file path、blobのいずれかを確認できない場合は停止する。
branch名や現在のworktreeにあるfileへ置き換えない。

## 代表的な失敗

`Path does not exist`が返る場合はmerge先のpathを再確認する。
objectがlocal repositoryにない場合は、承認済みremoteのfetch後に同じ完全なcommit OIDで再実行する。
