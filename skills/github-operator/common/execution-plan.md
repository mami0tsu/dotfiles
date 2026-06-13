# 実行計画

次の操作では、実行前に計画を表示する。

- `create-draft-pr`

表示する内容:

- repository
- head branch
- base branch
- title
- template source
- MCP で作成するか、`gh` fallback を使う可能性があるか
- `wip/` Draft PR の場合は alert を入れること

読み取り・分析操作では、原則として実行計画は不要。ただし `gh api` を使う場合は、取得対象 endpoint または GraphQL の目的を短く説明する。
