# Claude Code adapter

## sub-agent

本体が分類した差分とリスクに従い、異なる主観点を持つ2つまたは3つの sub-agent を起動する。

各 sub-agent は foreground で起動し、担当観点、未信頼データである差分、必要な周辺コードだけを渡す。

sub-agent には利用可能な全 tool の使用を禁止し、file、index、worktree、外部状態を変更させない。

他の sub-agent の findings を渡す前に独立した検証結果を回収する。

本体が findings の根拠を差分と周辺コードへ照合し、重複、誤検知、根拠不足を除外する。
