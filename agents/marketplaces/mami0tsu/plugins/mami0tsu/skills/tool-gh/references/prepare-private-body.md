# prepare-private-body

## 目的

GitHubへ渡す本文をcommand lineへ含めず、権限`0600`の一時body fileへ保存する。

## 前提条件

- 標準入力から渡す承認済み本文
- `tool-gh`の専用scriptを解決した絶対path

## 推奨コマンド

本文をprocessの標準入力へ送り、次のcommandが終了するまで入力を閉じない。

```sh
bash "<plugin-root>/skills/tool-gh/scripts/private-body-file.sh" create
```

出力された絶対pathだけを後続の`--body-file`へ渡す。
一時fileのpathや本文をstateへ保存しない。

## 停止条件

標準入力へ本文を安全に送れない場合は、本文をargumentや環境変数へ移さず停止する。
