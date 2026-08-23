# 検証記録

## 静的確認

- 実行日：2026-08-23
- 対象：`impl-flow/SKILL.md`、`agents/openai.yaml`、fallback pull request template
- 確認内容：ticket、branch、worktree、pull request の一対一対応、base 解決、push 前 review、Draft pull request、stack link、振り返り、lease 付き force push の停止条件を照合した。
- 通常検証：`git diff --check`、`task validate:taskfile`、`claude plugin validate agents/marketplaces/mami0tsu/plugins/dev --strict`

## Agent シナリオ試験

### standalone pull request

- ticket graph：blocker なし。
- GitHub 状態：head branch に対応する pull request なし。default branch は `main`。
- 期待する判断：`origin/main`の OID から専用 branch と worktree を作り、base `main`の Draft pull request を一件作成する。`gh stack link`は実行しない。
- 拒否条件：同じ head branch の pull request が複数ある場合、または ticket、branch、worktree の対応が保存済み state と異なる場合は停止する。

### stack 最下層の pull request

- ticket graph：blocker はすべて `main`へ merge 済み。後続 ticket がこの ticket に block されている。
- GitHub 状態：この ticket の head branch に対応する pull request なし。
- 期待する判断：base `main`の Draft pull request を作成する。この時点では URL が一件だけなので stack 化しない。後続 ticket の `impl-flow`が二件目の Draft pull request を作成したあと、bottom URL と top URL を `gh stack link`へ渡す。
- 拒否条件：merge 済み blocker の pull request が default branch 以外へ merge されている場合は、default branch に依存が含まれることを確認できるまで停止する。

### stack 上位の pull request

- ticket graph：未merge blocker が同じ stack に二件あり、順序は `P-1`、`P-2`。対象 ticket は `P-2`に block されている。
- GitHub 状態：`P-1`と`P-2`は検証済み Draft pull request で同じ stack に属する。
- 期待する判断：最上位 blocker `P-2`の head branch を base にする。対象 Draft pull request の作成後、三件の URL を bottom から top の順に `gh stack link`へ渡し、base、head、Draft 状態、stack ID、順序を再検証する。
- 拒否条件：未merge blocker が別 stack に分かれる場合、blocker pull request が非 Draft の場合、既存 base が期待順と異なり変更が承認範囲にない場合は停止する。

### force push の境界

- active stack：workflow state に branch、ticket、pull request、base、head、remote OID が保存されている線形 stack。
- 期待する判断：人間が rebase と履歴変更を承認し、fetch 後の remote OID が保存値と一致するときだけ、branch と期待 OID を明示した `--force-with-lease`を許可する。
- 拒否条件：active stack 外、引数なしの lease、期待 OID の不一致、下位 branch の検証失敗では push しない。

### identity の不一致

- 入力：保存済み ticket と現在 branch の pull request が別 ticket を参照する。
- 期待する判断：既存 pull request を再利用せず、workflow state も上書きせず停止する。
- 同じ拒否を適用する対象：base、head、worktree path、pull request URL、stack ID の不一致。
