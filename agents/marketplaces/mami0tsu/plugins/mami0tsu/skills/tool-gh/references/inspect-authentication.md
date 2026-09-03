# inspect-authentication

指定したGitHub hostの認証状態を取得する[^gh-auth-status]。

## 入力

- GitHub host

## 出力

- 認証状態
- account
- tokenの権限

## 制約

- tokenの値を出力しない。
- 認証情報を追加、更新、削除しない。

## 手順

### 1. 認証状態を取得する

```sh
gh auth status --hostname <host>
```

### 2. 結果を返す

host、認証状態、account、tokenの権限を返す。

[^gh-auth-status]: [GitHub CLI `gh auth status` manual](https://cli.github.com/manual/gh_auth_status)
