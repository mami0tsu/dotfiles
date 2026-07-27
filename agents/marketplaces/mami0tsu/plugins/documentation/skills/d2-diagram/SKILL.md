---
name: d2-diagram
description: D2 0.7.1 で編集可能な構成図またはフロー図を作成し、SVG を出力、watch、視覚確認するときに使う。D2 ソースの新規作成、編集、描画に適用する。
---

# D2 Diagram

D2 ソースと SVG を対にして残す。

対象は構成図、フロー図、SVG 出力、watch、視覚確認と、それらを記述する最小の D2 記法である。

シーケンス図、ER 図、クラス図、複数 board、import、アイコン、テーマの選定は対象に含めない。

## 通常の進め方

1. 図の種類に応じて、[構成図とフロー図](references/architecture-and-flow.md) を読む。
2. `<name>.d2` にソースを書き、`d2 validate <name>.d2` を実行する。
3. [SVG 出力、watch、視覚確認](references/rendering-and-review.md) に従って SVG を生成し、画像として確認する。
4. 確認済みの `.d2` と `.svg` を成果物として残す。

## リファレンス

- [構成図とフロー図](references/architecture-and-flow.md)：shape、connection、container、label、style、layout を使って図を記述する。
- [SVG 出力、watch、視覚確認](references/rendering-and-review.md)：SVG の出力、編集時の watch、レイアウトの選択、表示結果の確認を行う。
- [検証記録](references/validation.md)：この Skill の静的確認とシナリオ試験の記録を確認する。

## ヘルプを参照する条件

検証済みの D2 0.7.1 で上記のユースケースを実行するときは、事前に `--help` を読まない。

要求が対象外である場合、インストール済みバージョンが `d2 v0.7.1` と異なる場合、または実行結果が未対応のオプションや構文変更を示す場合だけ、必要な範囲を確認する。

- **構文エラー**：D2 が示す行と列を起点に、キー、コロン、中括弧、接続演算子を修正してから `d2 validate <name>.d2` を再実行する。
  help は読まない。
- **バージョン差または未収録の描画、watch オプション**：`d2 --help` を使う。
  D2 0.7.1 には `validate` 専用の help がなく、`d2 validate --help` も CLI 全体の help を返すためである。
- レイアウト固有の確認では `d2 layout <engine>` を使う。

確認結果がこの Skill の記述を変える場合は、該当リファレンスの情報源、検証バージョン、確認コマンドを更新する。
