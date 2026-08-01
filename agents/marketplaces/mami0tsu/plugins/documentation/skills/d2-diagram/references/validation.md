# 検証記録

## 静的確認

- 実行日：2026-07-26
- 実行環境：macOS、D2 `v0.7.1`
- 確認内容：`SKILL.md` から2つの CLI 操作リファレンスとこの記録への導線があり、対象ユースケース、情報源、完全な検証バージョン、確認コマンド、ヘルプの限定条件を確認した。
  D2 0.7.1 では `d2 validate --help` が `d2 --help` と同じ CLI 全体の help を返し、`validate` 専用 help はないことも確認した。
- Plugin 検証：`claude plugin validate agents/marketplaces/mami0tsu/plugins/documentation --strict` が成功した。

## シナリオ 1：構成図を dagre で SVG と PNG に出力する

- 実行日：2026-07-26
- 実行環境：macOS、D2 `v0.7.1`
- 入力と対象ユースケース：container、cylinder、接続ラベルを持つ構成図を作成し、dagre で SVG を出力する。
- 読み込んだ参照ファイル：`architecture-and-flow.md`、`rendering-and-review.md`
- CLI のバージョンと実行したヘルプコマンド：`d2 v0.7.1`。通常経路ではヘルプを実行しない。
- 実行結果：`d2 validate architecture.d2`、`d2 --layout dagre architecture.d2 architecture.svg`、`rsvg-convert architecture.svg -o architecture-preview.png` が成功した。
  PNG を表示し、container、cylinder、接続の向きとラベルを確認した。
- 変更内容：なし。

## シナリオ 2：フロー図を SVG と PNG に出力する

- 実行日：2026-07-26
- 実行環境：macOS、D2 `v0.7.1`
- 入力と対象ユースケース：開始、判断、2つの終了経路を持つフロー図を作成し、SVG を出力して確認する。
- 読み込んだ参照ファイル：`architecture-and-flow.md`、`rendering-and-review.md`
- CLI のバージョンと実行したヘルプコマンド：`d2 v0.7.1`。通常経路ではヘルプを実行しない。
- 実行結果：`d2 validate flow.d2`、`d2 flow.d2 flow.svg`、`rsvg-convert flow.svg -o flow-preview.png` が成功した。
  PNG を表示し、開始から2つの終了経路までの矢印と分岐ラベルを確認した。
- 変更内容：なし。

## シナリオ 3：watch で SVG の更新を確認する

- 実行日：2026-07-26
- 実行環境：macOS、D2 `v0.7.1`
- 入力と対象ユースケース：一時ディレクトリ `/private/tmp/d2-watch-validation-p53` の構成図を `--watch` で起動し、入力を変更して SVG が再生成されることを確認する。
- 読み込んだ参照ファイル：`rendering-and-review.md`
- CLI のバージョンと実行したヘルプコマンド：`d2 v0.7.1`。通常経路ではヘルプを実行しない。
- 実行結果：`d2 --watch --browser 0 watch.d2 watch.svg` が `http://127.0.0.1:52282` を表示し、初回の `watch.svg` を生成した。
  初回 SVG は `Before` を含み、更新時刻は `1785041362`、SHA-256 は `2f36e16bfe852ae9c6399ceeeaa7e6ac039c4cdf0763fca393fad5adf227bbee` だった。
  `watch.d2` を `service: Before` から `service: After` へ変更して保存すると、watch が変更を検出して再コンパイルした。
  再生成後の SVG は `After` を含み、`Before` を含まず、更新時刻は `1785041395`、SHA-256 は `3fa91243d3e4ab09fd05303dc66c39521b14599513a92e633238cfecf7aa53c5` に変わった。
  検証後に watch プロセスを終了した。
- 変更内容：なし。

## シナリオ 4：対象外の TALA 要求を確認する

- 実行日：2026-07-26
- 実行環境：macOS、D2 `v0.7.1`
- 入力と対象ユースケース：TALA 固有のレイアウト設定を要求する。
- 読み込んだ参照ファイル：`rendering-and-review.md`
- CLI のバージョンと実行したヘルプコマンド：`d2 v0.7.1`、`d2 layout tala`
- 実行結果：インストール済み D2 が列挙するレイアウトは dagre と elk だけであり、TALA はこの Skill の検証済み対象外だと判断した。
- 変更内容：なし。

## シナリオ 5：構文エラーを行と列の診断で修正する

- 実行日：2026-07-26
- 実行環境：macOS、D2 `v0.7.1`
- 入力と対象ユースケース：閉じ中括弧を欠いた D2 ソースを検証し、構文エラーを修正する。
- 読み込んだ参照ファイル：`architecture-and-flow.md`、`rendering-and-review.md`
- CLI のバージョンと実行したヘルプコマンド：`d2 v0.7.1`。構文エラーの診断ではヘルプを実行しない。
- 実行結果：`d2 validate invalid.d2` は行と列を示す parser 診断を返した。
  診断位置の中括弧を修正した後、`d2 validate invalid.d2` が成功した。
- 変更内容：なし。
