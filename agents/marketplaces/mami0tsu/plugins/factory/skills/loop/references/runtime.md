# 実行入力

各 [スクリプト](../../../scripts/)は `python3 <plugin-dir>/scripts/<name>.py --input <input.json>` で JSON object を受け取り、`status: success | wait | error` を返す。
`--input` の省略時は標準入力を使う。
すべての入力に設定の絶対パス `config` を含める。

| スクリプト | 追加入力 | 出力 |
| --- | --- | --- |
| `loop_status` | なし | 再開する `entries` |
| `loop_discover` | `manual: candidate[]`、`results: result[]` | 手動、完了記録の次工程、期限到来した調査の `candidates` |
| `loop_claim` | `candidate` | 予約の `claim,token,input,refs` |
| `loop_attach` | `claim,token,child` | native 子との対応 |
| `loop_write` | `claim,token,child,key,operation` | 書き込みの記録 |
| `loop_finish` | `claim,token,child,result,childTerminated`、任意の `humanWait,unknownWrites` | 終了または保留した `phase` |
| `loop_reconcile` | `claim,token,child,childTerminated,writeChecks`、未起動時の `launchAbsent` | 照合済みの停止記録 |

| 型 | 値 |
| --- | --- |
| `candidate` | `skill,target,step,input: object,refs: object` を持つ。 |
| `target` | 正本の `id,url` と、取得済みの `revision` を持つ。 |
| `result` | `status,next,target,step` と、次の子へ渡す `nextInput,nextRefs` を持つ。 |
| `input,refs` | 子へ渡し、再開記録にも保持する。 |
| 子の `input.config,journal` | claim が canonical 設定と同じ場所の `.<設定名>.writes.json` を設定し、別の設定や journal は拒否する。 |
| 定期調査の `input` | `config,case: periodic,now,completedAt,cycle` を渡し、範囲は CUE の `repositories` を使う。 |
| `next` | worker 名または子を起動しない `human,none` とする。 |
| `operation` | MCP 書き込み前の `begin`、adapter で再取得した `observed`、未実行を確認した `not-written` とする。 |
| `key` | 再試行で変えない書き込みの識別子とする。 |
| `childTerminated` | native 機能で子の終了を確認した場合だけ `true` とする。 |
| `humanWait` | 人間の回答を待つ `wait` の場合だけ `true` とする。 |
| `writeChecks` | 未照合 key ごとの `observed | not-written` を渡す。 |
| `launchAbsent` | 子一覧で未起動を確認した予約だけ `true` とし、`child: null` を渡す。 |
| `phase` | `reserved,running,unknown` は処理枠を保持し、`done,waiting,stopped` は解放する。 |
| 保存先 | canonical 設定と同じ場所の `.<設定名>.runtime.json` とし、`.lock` の flock と atomic rename で更新する。 |
