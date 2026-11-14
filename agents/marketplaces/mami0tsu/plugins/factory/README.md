# Factory

アイデアの調査から成果物のリリースまでを進めるプラグインです。
現在はプラグインの登録だけに対応し、スキルは後続のチケットで追加します。

## スキルの配置

スキルは `skills/<name>/SKILL.md` に追加します。
各スキルは短い利用条件、入力、手順、出力から始め、複数のケースを扱う場合は内部で分岐します。
出力テンプレートは各スキルの `assets/` に置きます。
参照資料やスクリプトは必要になった時点で追加します。

| 追加予定のスキル | 役割 |
| --- | --- |
| `loop` | 状態の確認と処理の起動 |
| `research` | リポジトリ、アイデア、調査タスクの調査 |
| `review` | 候補、調査結果、成果物のレビュー |
| `register` | アイデアの登録 |
| `plan` | タスクへの分解と起票 |
| `design` | 設計成果物の作成と修正 |
| `implement` | 実装成果物の作成と修正 |
| `release` | 承認済み成果物のリリース |
| `respond` | コメントへの応答 |

ビルトインのアダプタースキル `linear` と `github` も `skills/` に追加します。
外部のアダプタースキルとの選択は、後続のチケットで一元設定に対応付けます。
Git 操作、設計、実装、レビューの既存手順は `dev` プラグインから再利用します。
人間による採用、承認、リリース判定は各処理の開始条件として確認します。

## 登録と削除

リポジトリのルートで実行します。

```sh
task agent-plugins:deploy:factory
task agent-plugins:clean:factory
```

`task agent-plugins:deploy` と `task agent-plugins:clean` でも対象になります。
Codex CLI は Agent Plugins 1.0.0 のルート manifest を使い、Claude Code は `.claude-plugin/plugin.json` を使います。
両 manifest の名前とバージョンはそろえて更新します。

## 参照する公開資料

- [Agent Plugins](https://agent-plugins.org/plugin-authors/build-an-agent-plugin)
- [Agent Skills](https://agentskills.io/skill-creation/best-practices)
- [OpenAI](https://developers.openai.com/plugins/build/plugins)
- [Anthropic のプラグイン仕様](https://code.claude.com/docs/en/plugins-reference)
- [Anthropic のスキル作成指針](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
