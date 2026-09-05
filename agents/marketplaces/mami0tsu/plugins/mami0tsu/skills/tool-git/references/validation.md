# 検証記録

## 2026-09-05：Commit時点のfile取得

- 実行環境：macOS、`git version 2.55.0`
- 入力：完全なcommit OIDとrepository rootからのfile pathを指定し、設計Documentの本文とSHA-256 digestを取得する。
- 対象ユースケース：`read-file-at-commit`
- 読み込んだreference：`read-file-at-commit.md`
- 実行したhelp：なし
- 結果：同じcommit OIDとfile pathから本文を取得し、worktree上のfileと一致するSHA-256 digestを得られた。

Remoteへの書き込みは行わず、local repositoryにあるcommitを使って検証した。
