# Claude Code adapter

## サブエージェント

レビューセッションの最初に Agent tool でサブエージェントを1つ起動する。

修正後は同じ agent ID を使って再開し、最新差分と検証結果を渡す。

サブエージェントには commit、Git index、worktree を変更させない。

## difit process

Bash tool で `review.py run` を foreground で起動する。

tool が background task ID を返した場合は、task output を取得して終了まで待つ。

ブラウザが閉じて command が終了するまで応答を完了しない。

browser の自動起動が permission rule で拒否された場合は、ユーザーの承認を得て再実行する。
