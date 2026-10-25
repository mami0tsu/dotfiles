# Update Nix hashes

Renovate が Nix パッケージや textlint の依存関係を変更した後に、hash を更新するローカルアクションです。
実行には Node.js 24、Git、flake に対応した Nix を使います。
コミット済みの `dist/index.js` を使うため、実行時に依存パッケージをインストールする必要はありません。

リポジトリをチェックアウトして Nix を導入した後、ワークフローから次のように呼び出します。

```yaml
- uses: ./.github/actions/update-nix-hashes
  with:
    mode: changed
```

| モード | 動作 |
| --- | --- |
| `changed`（既定） | `HEAD` から変更されたパッケージと textlint の依存関係、リビジョンが変更されたプラグインの hash を更新します。 |
| `all` | `legacy-plugins.nix` に定義した全プラグインの hash を更新します。 |
| `check` | ファイルを変更せず、`legacy-plugins.nix` に定義した全プラグインの hash を検証します。 |

どのモードでも、処理が成功すると最後に `nix flake check --no-build --no-update-lock-file` を実行します。

Renovate の `postUpgradeTasks` は、変更をコミットする前にコマンドを実行します。
Renovate コンテナ内でも、同じエントリーポイントを呼び出します。

```sh
node .github/actions/update-nix-hashes/dist/index.js
```

ローカルで検証するときは、このコマンドに `--changed`、`--all`、`--check` のいずれかを渡します。
CLI 引数の指定は、環境変数 `INPUT_MODE` の指定より優先されます。

pnpm の共通バージョンは、リポジトリルートの `package.json` で固定します。
このアクションと textlint は `pnpm-workspace.yaml` を通じて共通の指定を参照し、lockfile はそれぞれのプロジェクトで保持します。
CI と Renovate も、ルートのバージョン指定を使います。

Node.js の共通バージョンは、ルートの `package.json` の `engines.node` で指定します。
CI の `setup-node` と、Nix で構築する textlint と difit はこの指定を参照します。
アクションの `runs.using: node24` は GitHub Actions が提供する実行環境の指定です。
メジャーバージョンを変更する場合は、`runs.using` と `@types/node` の対応も確認します。

実装を変更する場合は、次のコマンドで型検査、ビルド、テストを実行します。

```sh
cd .github/actions/update-nix-hashes
pnpm install --frozen-lockfile --ignore-scripts
pnpm run typecheck
pnpm run build
pnpm test
```

再生成した `dist/index.js` は、TypeScript のソースと一緒にコミットします。
CI はアクションを再ビルドし、生成物の差分を検査してから、テストとローカルアクションの実行を確認します。
Renovate も、アクションの依存関係を更新したときにこのファイルを再生成します。
