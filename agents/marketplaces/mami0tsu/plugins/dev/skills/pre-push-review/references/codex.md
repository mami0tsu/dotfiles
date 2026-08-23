# Codex adapter

## サブエージェント

本体のリスク判定に従い、通常リスクでは1つ、高リスクでは異なる観点の2つまたは3つのサブエージェントを起動する。

修正後は同じ agent ID の各サブエージェントへ最新差分と検証結果を送り、指摘が0件になるまで続ける。

サブエージェントには commit、Git index、worktree を変更させない。

## difit process

shell tool で `pre_push_review.py run` を foreground で起動する。

command が session ID を返した場合は、その session を poll する。

ブラウザが閉じて command が終了するまで final response を返さない。

browser の自動起動が sandbox で拒否された場合は、同じ command を必要な権限で再実行する。
