# Agents

`agents/` には、agent の設定を再現するために Git で管理する手書きのソースを置きます。

`.agents/` は APM が展開する生成物です。

生成物を直接編集しても、次回の deploy で置き換わります。

## 構成

- `marketplaces/mami0tsu/`：Codex CLI と Claude Code が共有する plugin marketplace。
- `skills/apm.yml`：APM で取得する skill の依存定義。
- `skills/apm.lock.yaml`：依存定義から解決した commit を記録する lockfile。

Marketplace の登録と削除には、次の task を使います。

```sh
task agent-plugins:deploy
task agent-plugins:clean
```

## Skill の更新と展開

skill の追加や削除では、`agents/skills/apm.yml` を手動で編集します。

依存定義を変えた後は、lockfile を再生成します。

```sh
task agent-skills:lock
```

既存依存を新しい commit へ更新する場合は、次を実行します。

```sh
task agent-skills:update
```

どちらの操作も `.agents/skills/` には展開しません。

lockfile に記録した内容を展開し、Codex CLI と Claude Code の skill ディレクトリへリンクするには、次を実行します。

```sh
task agent-skills:deploy
```

deploy は一時的にリポジトリ直下へ lockfile を配置しますが、完了時と失敗時のどちらでも削除します。

`--frozen` で展開するため、manifest と lockfile が一致しない場合は失敗します。

生成した skill と管理対象の link を削除するには、次を実行します。

```sh
task agent-skills:clean
```

この task は `.agents/skills/` と管理対象の link を削除します。

`agents/skills/` にある manifest と lockfile は保持します。
