# Factory

Issue の調査から成果物のレビューまでを進めるプラグインです。
初期設定には [init スキル](skills/init/SKILL.md)を使います。
未実装の処理スキルは後続チケットで追加します。

## 初期設定

factory の `init` を呼び、`factory.json` を作成します。
保存先を指定しない場合は作業ディレクトリに作成します。
必要な値を確認した後、同梱の [CUE 定義](skills/init/assets/config.cue)で検証した JSON を生成します。
各パラメーターの説明、型、制約、既定値はこの CUE 定義で管理します。
利用者が CUE を編集する必要はありません。
既存の JSON は検証し、必要な値を確認したうえで不足分を補います。
旧設定では `roles.ideas` と `states.ideas` をそれぞれ `roles.issues` と `states.issues` に変更します。
`loop.skills.review` と `reviewers.review` がある場合は、それぞれ `review-pr` に変更します。
旧設定にある `loop.skills` と `reviewers` の `plan`、`register` は削除します。

生成と検証には CUE を使います。
CUE は Home Manager のパッケージと Nix の test 環境に含めます。
未導入の場合、スキルはインストールせず保留します。
処理スキルは必要な設定値を確認し、設定が存在しない場合や値が不足する場合は、同じパスと不足項目を渡して `init` を呼びます。

## 定期実行

`loop.skills` の各スキルに `intervalSeconds` を指定すると、実装済みのスキルをその間隔で実行します。
research、create-task、review-pr、respond、implement の既定値は3600秒です。
`loop.skills.research.maxOpenIssues` を指定すると、管理先の未クローズ Issue が上限に達している間は research を見送ります。
実行間隔ごとに再確認し、上限を下回ると再開します。

## タスクと出力先

Issue は GitHub に保存し、`roles.issues.repository` に保存先リポジトリの URL を指定します。
タスクを管理するサービス名は `roles.tasks.service` に指定します。
タスクの ID を構成するキーは `roles.tasks.key` に指定します。
そのサービスでタスクが着手可能であることを示す状態名は `states.tasks.ready` に指定します。
タスクの操作には、指定したサービスに対応するスキルを使います。
タスクの出力先は名前付きの `outputs` に定義します。
たとえば `outputs.code` と `outputs.docs` を定義し、タスクに `output: "code"` または `output: "docs"` を指定します。

| `kind` | 出力先 | 設定 |
| --- | --- | --- |
| `pull-request` | GitHub のプルリクエスト | `repository` に調査対象のリポジトリの URL を指定する |
| `wiki` | Wiki の記事 | `service` に Wiki のサービス名を指定する |
| `task-comment` | タスクのコメント | `roles.tasks` のサービスを使う |

`repositories` は最新のデフォルトブランチを定期調査する対象であり、管理先や出力先を兼ねるとは推測しません。

`create-task` は Issue 上で合意した各タスクに、設定内の出力先キーを1つ記録します。
たとえば `outputs.component-a` と `outputs.component-b` に対応する2つのタスクを合意した場合は、それぞれに `output: "component-a"` と `output: "component-b"` を記録し、合意した依存関係を設定します。
プルリクエストを使うタスクは1タスクにつき1リポジトリの1プルリクエストを扱います。
出力先が未指定、不明なキー、複数値、または受け入れ条件と矛盾する場合は、推測せず保留します。

選んだ出力先の参照は実装とレビューへ同じ値を引き継ぎます。
Issue、タスク、出力先、成果物の `id`、`url`、`revision` を関連付けて追跡します。
同じキーの設定先が変わり、記録済みの成果物や対象リポジトリと一致しない場合は保留し、別の出力先へ切り替えません。

## スキルの追加

各スキルは `skills/<name>/SKILL.md` に短い条件、入力、手順、出力を書き、ケースは内部で分岐します。
出力テンプレートは各スキルの `assets/`、必要な補足資料は各スキルの `references/` に置きます。
Git 操作や設計、実装、レビューの既存手順は `dev` プラグインから再利用します。

## 登録と削除

リポジトリのルートで実行します。

```sh
task agent-plugins:deploy:factory
task agent-plugins:clean:factory
```

全体の `deploy` と `clean` も factory を対象にします。
Codex CLI はルート manifest、Claude Code は `.claude-plugin/plugin.json` を使います。

## 公開資料

- [Agent Plugins](https://agent-plugins.org/plugin-authors/skills)
- [Agent Skills](https://agentskills.io/skill-creation/best-practices)
- [OpenAI](https://developers.openai.com/plugins/build/skills)
- [Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [CUE による JSON 検証](https://cuelang.org/docs/howto/validate-json-using-cue/)
