# 検証記録

## worktree の切り替え

- 実行日：2026-08-09
- 実行環境：macOS、Git 2.55.0、git-wt 0.27.0、`/Users/mami0tsu/dotfiles/.worktrees/P-80-worktree-switch`
- 確認内容：既存worktreeをbranchまたはpathで指定すると、`git wt --nocd` が同じabsolute pathを返すことを確認した。
- 確認内容：`--nocd` がshell integrationによるdirectory移動を抑止することを確認した。

### Agent シナリオ試験

- 入力と対象ユースケース：指定された既存worktreeを後続コマンドの実行先にする。
- 読み込んだ参照ファイル：`SKILL.md`、`references/worktree-list.md`、`references/worktree-switch.md`。
- 実施した操作：JSONのpathとbranchを確認し、`git wt --nocd` が返したabsolute pathを `git -C` に指定した。
- 結果：コマンド実行間のcurrent directoryに依存せず、意図したrepository root、branch、statusを確認できた。
- 停止経路：切り替え先が一覧にない場合は、`git wt` を実行せず停止することを確認した。

## worktree の作成

- 実行日：2026-08-09
- 実行環境：macOS、Git 2.55.0、git-wt 0.27.0、`/Users/mami0tsu/dotfiles/.worktrees/P-79-worktree-create`
- 確認内容：`git wt --nocd -b <branch> <worktree> <start-point>` が指定した起点から branch と worktree を作成することを確認した。
- 確認内容：`git wt --nocd -b <branch> <worktree>` が、どの worktree にも割り当てられていない既存 branch を再利用することを確認した。
- 確認内容：割り当て済みの branch を指定すると既存 path を返して exit code 0 になるため、作成前の一覧確認が必要であることを確認した。

### Agent シナリオ試験

- 入力と対象ユースケース：新規 branch と既存 branch に、それぞれ専用 worktree を作成する。
- 読み込んだ参照ファイル：`SKILL.md`、`references/worktree-list.md`、`references/worktree-create.md`、`references/remote-integration.md`。
- 実施した操作：branch と worktree の一覧を確認し、`git wt --nocd -b` で作成した後、JSON の path と branch、および作成先の status を照合した。
- 結果：worktree 名と branch 名を分け、確認済みの起点または既存 branch から clean な worktree を作成できた。
- 停止経路：同じ branch が worktree に割り当てられている場合は、既存 path を報告し、作成コマンドを実行せず終了することを確認した。

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
- 読み込んだ参照ファイル：`SKILL.md`、`references/worktree-create.md`、`references/state-and-branch.md`、`references/remote-integration.md`。
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
