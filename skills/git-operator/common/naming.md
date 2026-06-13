# 命名ルール

## ticket-id

通常 branch には ticket-id を必ず含める。ticket-id がない branch は検証用またはチケット作成前の `wip/` branch として扱う。

ticket-id は次の情報から抽出する。

- Jira/Linear: `ABC-123` 形式の issue key
- GitHub Issue URL: `/issues/<number>` から取得し、既存規約がなければ `GH-<number>` とする
- ユーザーが明示した ID

既存 branch 名に GitHub Issue 用の明確な規約がある場合は、それを優先する。

ticket-id が取れない場合は、ユーザーに次の選択肢を示す。

- ticket-id を入力する
- `wip/<short-description>` として作る
- 作成を中止する

通常 branch を ticket-id なしで作らない。

## branch name

リポジトリに既存規約が明確にある場合はそれを優先する。明確でない場合の標準形式:

```text
<type>/<ticket-id>/<short-description>
```

例:

```text
feature/ABC-123/add-login-form
hotfix/ABC-456/prevent-null-error
chore/ABC-789/update-dev-tooling
```

ticket-id がない検証用 branch:

```text
wip/<short-description>
```

`type` は依頼内容から保守的に選ぶ。

- `feature`: 新機能、ユーザー向け変更
- `hotfix`: 不具合修正、緊急修正
- `chore`: 保守、設定、ツール、ドキュメント整備
- `wip`: ticket-id 作成前の検証、叩き台

上記以外の `type` は自動で選ばない。既存規約から明確に必要だと判断できる場合でも、ユーザーに確認する。

`create-worktree` で作成する branch 名も、この branch name ルールに従う。worktree 名は branch 名ではなく、ディレクトリ名として slash を避けた派生名にする。

## short-description

英小文字、数字、hyphen を使う。slash は含めない。URL やチケットタイトルから作る場合も短くする。

## worktree name

worktree 名は branch 名ではない。worktree 名には slash を含めない。

ticket-id 付き branch の worktree 名:

```text
<type>-<ticket-id>-<short-description>
```

例:

```text
feature-ABC-123-add-login-form
hotfix-ABC-456-prevent-null-error
chore-ABC-789-update-dev-tooling
```

`wip/` branch:

```text
wip-<short-description>
```

## commit message

標準形式:

```text
<type>: <summary> <ticket-id>
```

例:

```text
feat: ログインフォームを追加 ABC-123
fix: null 入力時の例外を防止 ABC-456
chore: Git 操作スキルを追加 ABC-789
```

`wip/` branch では ticket-id なしの `<type>: <summary>` を許可する。ただし `promote-wip-branch` では、merge される branch の commit message を揃えるため、分岐後の全 commit に ticket-id を付与する。
