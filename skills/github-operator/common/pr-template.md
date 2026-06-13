# PR template

## title

通常 Draft PR の title:

```text
<short-summary> <ticket-id>
```

`wip/` branch の Draft PR title:

```text
WIP: <short-summary>
```

## repository template

PR body は repository の template を最優先する。

確認する場所:

```text
.github/pull_request_template.md
PULL_REQUEST_TEMPLATE.md
docs/PULL_REQUEST_TEMPLATE.md
.github/PULL_REQUEST_TEMPLATE/*.md
.github/pull_request_template/*.md
```

template が 1 つだけ見つかった場合はそれを使う。複数見つかった場合はユーザーに選択させる。

## fallback template

repository template がない場合は、この skill の fallback template を使う。

普段は日本語テンプレートを使う。ユーザーが英語を指定した場合、または repository が明確に英語運用の場合だけ英語にする。

日本語:

```markdown
## 概要

## 変更内容

## レビュー観点

## 参考情報
```

英語:

```markdown
## Summary

## Changes

## Review Notes

## References
```

`レビュー観点` には、確認してほしい箇所、設計判断、トレードオフをまとめて書く。

## wip alert

`wip/` branch の Draft PR では、body の冒頭に次を追加する。

```markdown
> [!WARNING]
> 本 PR は仮実装なのでマージはしません。

```
