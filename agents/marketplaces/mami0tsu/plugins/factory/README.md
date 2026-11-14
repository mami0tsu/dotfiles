# Factory

アイデアの調査から成果物のリリースまでを進めるプラグインです。
初期設定には [init スキル](skills/init/SKILL.md)を使います。
`loop` などの処理スキルは後続チケットで追加します。

## 初期設定

factory の `init` を呼び、`factory.json` の保存先を指定します。
必要な値を確認した後、同梱の [CUE 定義](skills/init/assets/config.cue)で検証した JSON を生成します。
各パラメーターの説明、型、制約、既定値はこの CUE 定義で管理します。
利用者が CUE を編集する必要はありません。
既存の JSON は検証し、無断では上書きしません。

生成と検証には CUE を使います。
CUE は Home Manager のパッケージと Nix の test 環境に含めます。
未導入の場合、スキルはインストールせず保留します。
各処理スキルは開始時に同じ定義で設定を検証し、標準出力の既定値補完済み JSON を使います。
設定が存在しない場合だけ `loop` から同じパスを渡して `init` を呼びます。

## タスクと出力先

アイデアとタスクの管理先は `roles.ideas` と `roles.tasks` に指定します。
タスクの出力先は名前付きの `outputs` に定義し、ファイル、コメント、変更提案を選べます。
変更提案そのものも成果物として扱います。
`repositories` は定期調査の対象であり、管理先や出力先を兼ねるとは推測しません。

後続の `plan` は、タスクに設定内の出力先キーを1つ記録する契約とします。
たとえば別々のリポジトリを指す `outputs.component-a` と `outputs.component-b` があれば、両方の変更を含むアイデアは2つのタスクへ分け、それぞれに `output: "component-a"` と `output: "component-b"` を記録し、タスク間の依存関係を設定します。
変更提案を使うタスクは、1タスクにつき1リポジトリの1変更提案を扱います。
出力先が未指定、不明なキー、複数値、または受け入れ条件と矛盾する場合は、推測せず保留します。

選んだ出力先の参照は、実装、レビュー、リリースへ同じ値を引き継ぎます。
アイデア、タスク、出力先、成果物の `id`、`url`、`revision` を関連付けて追跡します。
同じキーの設定先が変わり、記録済みの成果物や対象リポジトリと一致しない場合は保留し、別の出力先へ切り替えません。
タスク分割と出力先選択の実装は、後続の処理スキルで追加します。

## アダプターの共通契約

管理先と出力先にアダプターと操作先を指定し、同じアダプターを複数の箇所に割り当てられます。
ビルトインと外部スキルは提供元だけが異なり、同じ設定項目と次の操作を受け取ります。
独自の設定項目は受け付けません。
`staging`、`artifacts`、`changes` は操作上の役割であり、タスクが選んだ同じ出力先を使います。

| 役割 | 操作先の種類 | 操作 |
| --- | --- | --- |
| `ideas` | `collection` | `list`, `get`, `create`, `comments`, `comment`, `decision` |
| `tasks` | `collection` | `list`, `get`, `create`, `update`, `comment` |
| `staging`, `artifacts` | `file`, `comment`, `change` | `get`, `save` |
| `changes` | `change` | `get`, `create`, `request-review`, `approval`, `merge` |

操作先の識別子はアダプターが接続先の表現へ変換します。
実行前に、指定スキルの存在と、役割、操作先の種類、操作への対応を確認します。
未対応なら停止または保留し、別のアダプターへ暗黙に切り替えません。

依頼には `role`、`target`、`operation`、`input`、更新時には再試行を照合する安定した `key` を渡します。
コメントの `subject` は、現在処理中のアイデアやタスク、または固定 URL を指します。
呼び出し元は実行時にその対象を解決し、対象の `id` と `url` を `input` に渡します。
既存コメントの取得や更新に使う識別子は、操作の入力と結果で受け渡します。
結果には `status: success | wait | error`、`items`、`reason` を返します。
各項目は `id` と `url`、成果物と変更提案では `revision` も持ちます。
採用と承認は人間の判断の根拠を確認し、リリースでは承認対象の版とタスクのリリース可能状態を照合します。
結果が不明な書き込みは保留し、再実行前に既存結果を照合します。

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
