# Codex adapter

設計のリスクと component に合わせて、異なる専門性を持つ sub-agent を2つまたは3つ起動する。
各 agent は read-only の検証だけを行い、file、Git index、workflow state、ticket を変更しない。

修正後は同じ agent ID に新しい設計案と、前回 finding に対応した事実だけを渡す。
他の agent の finding または期待する結論は渡さない。
