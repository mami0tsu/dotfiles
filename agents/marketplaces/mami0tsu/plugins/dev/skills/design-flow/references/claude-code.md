# Claude Code adapter

Agent tool で、異なる専門性を持つ sub-agent を2つまたは3つ同時に起動する。
各 agent には read-only の検証だけを許可し、file、Git index、workflow state、ticket を変更させない。

修正後は同じ agent を resume し、新しい設計案と前回 finding に対応した事実だけを渡す。
他の agent の finding または期待する結論は渡さない。
