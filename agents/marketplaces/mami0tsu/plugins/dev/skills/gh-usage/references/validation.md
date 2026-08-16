# 検証記録

## 静的確認

- 実行日：2026-07-26
- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`、`/Users/mami0tsu/dotfiles/.worktrees/P-52-improve-gh-usage`
- 確認内容：frontmatter、`agents/openai.yaml`、`references/`、`SKILL.md` からの参照、全ユースケースの必須項目、情報源、限定した help fallback を確認した。
- 実行コマンド：`git diff --check`、`task agent-plugins:validate`
- 結果：`task agent-plugins:validate` は dev plugin、doc plugin、marketplace の strict validation を通過した。

## Agent シナリオ試験

### 実行経路

- 実行日：2026-07-26
- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`、`/Users/mami0tsu/dotfiles/.worktrees/P-52-improve-gh-usage`
- 入力と対象ユースケース：`mami0tsu/dotfiles` の pull request #56 と GitHub Actions check を読み取る。
- 読み込んだ参照ファイル：`SKILL.md`、`references/common.md`、`references/pull-requests.md`、`references/actions-and-review-comments.md`
- CLI のバージョンと実行した help コマンド：`gh --version`。シナリオ実行前の help 参照はなし。
- 実行コマンド：`gh pr view 56 --repo mami0tsu/dotfiles --json number,title,body,state,isDraft,author,baseRefName,headRefName,reviewDecision,mergeStateStatus,url`、`gh pr checks 56 --repo mami0tsu/dotfiles --json name,state,bucket,workflow,link`
- 結果と変更内容：PR #56 の base、head、merge 状態、URL と、`Nix Config Test` の pass check を取得した。reference の変更は不要だった。

### review comment の実行経路

- 実行日：2026-07-26
- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`、`/Users/mami0tsu/dotfiles/.worktrees/P-52-improve-gh-usage`
- 入力と対象ユースケース：`mami0tsu/dotfiles` の pull request #56 の inline review comment を読み取る。
- 読み込んだ参照ファイル：`SKILL.md`、`references/actions-and-review-comments.md`
- CLI のバージョンと実行した help コマンド：`gh --version`。シナリオ実行前の help 参照はなし。
- 実行コマンド：`gh api graphql --paginate` と、`url`、`reviewThreads`、`comments`、`isResolved`、`isOutdated`、path、line、commit field を含む read-only query。
- 結果と変更内容：query は PR #56 の URL と空の review thread 一覧を返した。初回の query は thread に存在しない `originalCommit` field を指定して失敗したため、comment の field へ移して再試験した。

### GraphQL field の照合

- 実行日：2026-07-26
- 一次情報：[Pull requests GraphQL reference](https://docs.github.com/en/graphql/reference/pulls)
- 確認内容：`PullRequest` の `number`、`url`、`reviewThreads`、`PullRequest.reviewThreads` が `first` と `after` を受け取ること、`PullRequestReviewThread` の `comments`、`isResolved`、`isOutdated`、`path`、`line`、`originalLine`、`diffSide`、`PullRequestReviewComment` の `author`、`body`、`createdAt`、`url`、`commit`、`originalCommit` を照合した。
- 確認コマンド：認証済み環境では `gh api graphql -f query='query { pullRequest: __type(name: "PullRequest") { fields { name } } thread: __type(name: "PullRequestReviewThread") { fields { name } } comment: __type(name: "PullRequestReviewComment") { fields { name } } }'` を使う。ページネーションの形は `gh api graphql --help` と query の `$endCursor: String`、`pageInfo { hasNextPage endCursor }` で確認した。
- 結果：既存の実行記録は `url` を返す query を確認している。今回の read-only query は API 接続エラーで停止し、`gh auth status` では default account の token が無効だった。そこで introspection は再実行せず、公式 GraphQL reference と既存の実行記録を照合した。`number` と `url` は `PullRequest` の field である。`originalCommit` は `PullRequestReviewThread` の field ではなく `PullRequestReviewComment` の field である。推奨 query は pull request の node に `number` と `url`、comment の node にだけ `originalCommit { oid }` を指定している。

### フォールバック経路

- 実行日：2026-07-26
- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`、`/Users/mami0tsu/dotfiles/.worktrees/P-52-improve-gh-usage`
- 入力と対象ユースケース：`gh pr checks` の JSON field を復旧し、対象外の `gh issue create` は command 固有の help だけを参照する。
- 読み込んだ参照ファイル：`SKILL.md`、`references/common.md`、`references/actions-and-review-comments.md`
- 通常経路：`gh --version` の後に `gh auth status` を実行した。default account の token が invalid だったため、認証が必要な pull request と GraphQL query の実行を停止した。
- フォールバックで実行したコマンド：`gh pr checks 56 --repo mami0tsu/dotfiles --json unsupportedField`、`gh pr checks --help`、`gh issue create --help`。
- 結果と変更内容：最初のコマンドは `Unknown JSON field: "unsupportedField"` と有効 field の一覧を返した。続けて `gh pr checks --help` だけで `bucket`、`completedAt`、`description`、`event`、`link`、`name`、`startedAt`、`state`、`workflow` を確認した。global help は参照していない。対象外の操作は `gh issue create --help` だけを参照し、作成操作は実行していない。

### pending review の構文と停止経路

- 実行日：2026-08-16
- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`、`/Users/mami0tsu/dotfiles/.worktrees/P-95-gh-usage`
- 入力と対象ユースケース：pending review の作成、新規 thread、既存 thread への reply、review body 更新を submit なしで構成する。
- 読み込んだ参照ファイル：`SKILL.md`、`references/common.md`、`references/actions-and-review-comments.md`、`references/pending-reviews.md`
- schema 確認：`AddPullRequestReviewInput`、`AddPullRequestReviewThreadInput`、`AddPullRequestReviewThreadReplyInput`、`UpdatePullRequestReviewInput`を`gh api graphql`の`__type` query で取得した。
- 結果：`event`は optional、thread と reply は pending review ID を受け取り、review body 更新は review ID と body を必須とすることを確認した。実 repository への mutation は実行していない。
- 停止経路：workflow state にない既存 pending review、異なる author または pull request、非`PENDING` state、head OID 不一致では書き込みを停止する。`submitPullRequestReview`、resolve 系 mutation、即時公開 comment は許可対象に含めない。

### 既存 Draft pull request の stack 化

- 実行日：2026-08-16
- 実行環境：macOS、`gh version 2.96.0 (nixpkgs)`、`gh stack version 0.1.0`、`/Users/mami0tsu/dotfiles/.worktrees/P-95-gh-usage`
- 入力と対象ユースケース：個別に作成済みの Draft pull request URL を、bottom から top の順で stack 化する。
- 読み込んだ参照ファイル：`SKILL.md`、`references/pull-requests.md`、`references/stacked-pull-requests.md`
- CLI の確認：`gh stack --version`、`gh stack link --help`を実行した。
- 結果：`link`は PR URL を受け取り、`--open`を省略でき、既存 PR の base を stack 順へ更新することを確認した。実 repository の stack は変更していない。
- 停止経路：2件未満、非線形依存、別 repository、非 Draft、別 stack 所属、base 変更が未承認の場合は実行しない。
