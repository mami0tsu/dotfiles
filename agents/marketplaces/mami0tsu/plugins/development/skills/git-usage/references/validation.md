# 検証記録

## worktree の一覧

- 実行日：2026-08-09
- 実行環境：macOS、Git 2.55.0、git-wt 0.27.0、`/Users/mami0tsu/dotfiles/.worktrees/P-78-worktree-list`
- 確認内容：`git wt -v` が `git-wt version 0.27.0` を出力することを確認した。
- 確認内容：`git wt --json --nocd` が各 worktree の `path`、`branch`、`head`、`current` を出力することを確認した。

### Agent シナリオ試験

- 入力と対象ユースケース：現在の worktree と、登録された worktree の path と branch を取得する。
- 読み込んだ参照ファイル：`SKILL.md`、`references/worktree-list.md`。
- 実施した操作：`git wt -v` で利用可否を確認し、`git wt --json --nocd` の `current`、`path`、`branch` を照合した。
- 結果：現在地を変更せず、登録された path と branch、および現在の worktree を取得できた。
- 停止経路：`git wt` が利用できない場合は `git worktree` へ切り替えず、一覧を取得できない状態で停止することを確認した。

## 静的確認

- 実行日：2026-07-26
- 実行環境：macOS、Git 2.55.0、`/Users/mami0tsu/dotfiles/.worktrees/P-51-improve-git-usage`
- 確認内容：`SKILL.md` から4つの CLI 操作リファレンスと本記録へ直接リンクし、8つの対象ユースケースを対応付けた。
- 確認内容：各 CLI 操作リファレンスに情報源、検証 version、確認コマンド、目的、前提条件、推奨コマンド、結果の確認、停止条件、代表的な失敗を記載した。
- 確認内容：`git --version` と対象 subcommand のヘルプで Git 2.55.0 の構文を確認した。
- 確認内容：`task agent-plugins:validate` を実行し、development plugin、documentation plugin、marketplace の strict validation が通過した。

## Agent シナリオ試験

### 通常経路

- 実行日：2026-07-26
- 実行環境：Git 2.55.0 の一時 repository。
- 入力と対象ユースケース：専用 worktree を作成し、状態を確認して default branch を `git pull --ff-only` で更新する。
- 実施した操作：`git fetch` 後に作業 branch を rebase し、diff を確認して `git push -u` で公開する。
- 読み込んだ参照ファイル：`SKILL.md`、`references/worktrees.md`、`references/state-and-branch.md`、`references/remote-integration.md`。
- CLI version とヘルプコマンド：`git version 2.55.0`。
  事前の `--help` 参照なし。
- 結果：worktree、status、`pull --ff-only`、fetch、rebase、diff、`push -u` をリファレンスだけで完了した。

### フォールバック

- 実行日：2026-07-26
- 実行環境：Git 2.55.0。
- 入力と対象ユースケース：対象外の tag 操作を依頼した。
- 読み込んだ参照ファイル：`SKILL.md`。
- CLI version とヘルプコマンド：`git version 2.55.0`、`git tag --help`。
  `git --help` と対象外の subcommand のヘルプは読まなかった。
- 結果：tag は対象外であることを明示し、必要な `git tag --help` だけを参照した。
