# Codex adapter

## サブエージェント

レビューセッションの最初にサブエージェントを1つ起動する。

修正後は同じサブエージェントへ最新差分と検証結果を送り、指摘が 0 件になるまで続ける。

サブエージェントには commit、Git index、worktree を変更させない。

## difit process

shell tool で `review.py run` を foreground で起動する。

command が session ID を返した場合は、その session を poll する。

ブラウザが閉じて command が終了するまで final response を返さない。

browser の自動起動が sandbox で拒否された場合は、同じ command を必要な権限で再実行する。
