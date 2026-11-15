# Factory

アイデアの調査からレビュー済み成果物の記録までを進めるプラグインです。
レビュー後の公開は人間が行います。

## 設定

[init](skills/init/SKILL.md) に `factory.json` の絶対パスを渡します。
型、制約、既定値は [CUE 定義](skills/init/assets/config.cue)だけで管理します。
Python 3 は CUE の呼び出し、入力の生成、結果の検証を担います。
既存設定は検証だけを行い、不正でも上書きしません。
未作成の場合だけ回答から生成し、必須値が不明なら `wait` を返します。
CUE が未導入なら保留します。

`roles.ideas` と `roles.tasks` は管理先です。
タスクは `outputs` のキーを1つ選び、以後の工程へ引き継ぎます。
出力先はファイル、コメント、変更提案から選びます。
複数のリポジトリへ変更する場合はタスクを分割します。
`repositories` は周期調査の対象です。
記録した出力先、対象、成果物の `id,url,revision` が現在の設定や正本と異なる場合は保留します。

## 実行

[loop](skills/loop/SKILL.md) は手動対象、周期調査、worker の成功結果から候補を選びます。
各作業の Python スクリプトが、全体とスキル別の上限、同一対象と工程の排他、子の再開記録を扱います。
LLM は native 子を起動し、内容を判断します。
独自の子プロセス基盤や待ち行列は持ちません。
記録の場所と呼び出し形式は [実行契約](skills/loop/references/runtime.md)を参照してください。

worker は `research`、`review`、`register`、`plan`、`design`、`implement`、`respond` です。
各 worker は次の工程を返し、子を直接起動しません。
人間待ちは native 子の終了確認後に処理枠を解放します。
未確認の子と結果不明の書き込みは枠を保持し、再開時に照合します。

## アダプター

設定の `adapters` は builtin の skill または external の plugin と skill を指定します。
導入済みカタログから解決し、指定先の入力契約と対応操作を確認します。
未知の設定項目や自由な接続オプションは追加しません。
接続済み MCP ツールを使い、サービス SDK や別の API 認証は追加しません。
Python はツール引数と結果を検証し、API 呼び出し自体は MCP ツールが行います。

| 役割 | target.kind | 操作 |
| --- | --- | --- |
| `ideas` | `collection` | `list,get,create,comments,comment,decision` |
| `tasks` | `collection` | `list,get,create,update,comments,comment` |
| `staging,artifacts` | `file,comment,change` | `get,save` |
| `changes` | `change` | `get,comments,comment,create,request-review` |

依頼は `config,role,target,operation,input` と、更新を照合する安定した `key` を持ちます。
出力先を使う操作ではタスクの単一 `output` と記録した binding も渡します。
結果は `status: success | wait | error` とし、対象の `id,url`、成果物の `revision` を保持します。
コメントは全ページの取得範囲、親と root の参照、発言者、日時、本文、版を区別します。
未対応の操作、版の不一致、取得範囲の不足は保留し、暗黙に別の対象や形式へ切り替えません。
結果不明の書き込みは、同じ key の既存結果を照合するまで繰り返しません。

## 登録と削除

リポジトリのルートで実行します。

```sh
task agent-plugins:deploy:factory
task agent-plugins:clean:factory
```

Codex CLI はルート manifest、Claude Code は `.claude-plugin/plugin.json` を使います。
各 skill は入力、出力、制約、手順を短く書き、決定論的な処理を作業別スクリプトへ置きます。

## 公開資料

- [Agent Plugins](https://agent-plugins.org/plugin-authors/skills)
- [Agent Skills](https://agentskills.io/skill-creation/best-practices)
- [OpenAI](https://developers.openai.com/plugins/build/skills)
- [Anthropic](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
