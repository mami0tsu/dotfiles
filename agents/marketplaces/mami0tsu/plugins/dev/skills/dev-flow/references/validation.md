# 検証記録

## 構造検査

- 対象：`dev-flow/SKILL.md`、`agents/openai.yaml`、plugin README、manifest
- 確認項目：root ticket の境界、下位 flow の選択、namespace の分離、人間待ち、merge 完了条件が一致する。
- 確認項目：`dev-flow`が実装、review submit、thread resolve、mergeを直接実行する指示を持たない。
- 確認項目：README、Skill metadata、plugin version が coordinator 構成を公開している。

## 再開シナリオ

### 生の要求

ticket がない要求を入力する。
`design-flow`が root ticket 案を含む承認済み設計を返した後、artifact digest に結び付いた proposal workflow を初期化することを確認する。
`ticket-flow`が同じ状態へ正本 root ticket と実装 ticket graph を記録するまで、実装へ進まないことを確認する。

### 既存 root ticket

受け入れ条件と単一 PR の計画を持つ root ticket を入力する。
子 ticket を作らず、root ticket 自体を`impl-flow`へ渡すことを確認する。

### 単一 pull request

Draft pull request が作成済みの root ticket を入力する。
同じ ticket の実装を再実行せず、feedback があれば`pr-review-response-flow`を、なければ review または merge の人間待ちを選ぶことを確認する。

### 複数 stack

root 配下に複数の独立 stack がある状態を入力する。
各 stack の block 関係を保持し、実装可能な ticket だけを進め、review response は各 stack の bottom から top の順になることを確認する。

### review response

stack の下層と上層に未処理 feedback がある状態を入力する。
下層の pending reply まで完了する前に上層を処理せず、review submit と thread resolve を人間待ちとして残すことを確認する。

### merge 待ち

全 check と review を満たした未merge pull request を入力する。
merge を実行せず人間待ちを返し、再実行時に merge、base、head、stack を再取得することを確認する。
記録済み pull request の merge と、それに伴う上層の base、head、check の変化は期待済み transition として受理し、工程を再選択することを確認する。

### 親 workflow の review response

`dev-flow`の workflow ID と pull request URL を`pr-review-response-flow`へ渡す。
別のトップレベル状態を作らず、同じ状態の`pr-review-response-flow` namespace だけを更新することを確認する。

### 範囲外 blocker

root 配下の実装 ticket が root 外の ticket に block されている状態を入力する。
範囲外 ticket を更新または実装せず、その完了を待機条件として扱うことを確認する。

### 完了

root 配下の全実装 pull request が merge 済みの状態を入力する。
ticket、pull request、stack を外部状態へ照合した後だけトップレベル workflow を完了することを確認する。
