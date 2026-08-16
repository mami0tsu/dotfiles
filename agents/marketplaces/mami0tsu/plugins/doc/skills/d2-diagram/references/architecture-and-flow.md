# 構成図とフロー図

## 情報源

- 公式ドキュメント：[Shapes](https://d2lang.com/tour/shapes/)、[Connections](https://d2lang.com/tour/connections/)、[Containers](https://d2lang.com/tour/containers/)、[Styles](https://d2lang.com/tour/style/)、[Layouts](https://d2lang.com/tour/layouts/)
- 検証バージョン：`d2 v0.7.1`
- 確認コマンド：`d2 --version`、`d2 layout`、`d2 layout dagre`

キーは図の要素を参照するための識別子であり、表示ラベルとは分ける。

表示文言を変更しても接続先が変わらないように、接続ではラベルでなくキーを使う。

## 最小の D2 記法

```d2
direction: right

client: クライアント
service: API
database: PostgreSQL {
  shape: cylinder
  style.fill: "#e8f1ff"
}

client -> service: HTTPS
service -> database: query
```

- **shape**：`shape: cylinder` のように表示形状を指定する。
  標準の形状は rectangle である。
- **connection**：`->` は方向を持つ接続である。
  接続ラベルは `source -> target: label` と書く。
- **container**：中括弧内に子要素を置く。
  `production: 本番環境 { api: API }` のように、キーと表示ラベルを分けられる。
- **label**：`api: API` の右側が表示ラベルである。
  キーに空白や説明文を混ぜない。
- **style**：`style.fill`、`style.stroke`、`style.font-color` を必要な要素だけに指定する。
  色と装飾を増やす前に、接続方向とラベルだけで読める状態にする。
- **layout**：`direction: right`、`direction: down`、`direction: left`、`direction: up` で全体の流れを指定する。
  標準のレイアウトエンジンは dagre である。

### 構成図を作成する

#### 目的

境界、配置先、主要コンポーネント、通信方向を一枚で確認できる構成図を `.d2` と SVG で残す。

#### 前提条件

図に含める要素、要素の境界、方向を持つ通信を確定する。

実装詳細、全設定値、監視項目まで一枚に詰め込む必要がある場合は、図の目的を分けて利用者に確認する。

#### 推奨コマンド

1. 外部要素、container、内部要素、接続の順に書く。
2. 主要な配置境界には container を使う。
3. サービスには rectangle、データストアには `shape: cylinder` など、読み分けに必要な shape だけを使う。
4. `d2 validate architecture.d2` を実行する。

```d2
direction: right

user: 利用者

production: 本番環境 {
  style.fill: "#f3f8ff"

  api: API
  database: PostgreSQL {
    shape: cylinder
    style.fill: "#e8f1ff"
  }
}

user -> production.api: HTTPS
production.api -> production.database: query
```

#### 結果の確認

`d2 validate architecture.d2` が成功することを確認する。

SVG を生成した後、container の内外、データストアの形状、接続の向きとラベルを画像で確認する。

#### 停止条件

通信の方向、境界への所属、または利用者に見せる粒度が不明な場合は、推測で接続や container を追加せず確認する。

#### 代表的な失敗

- **症状**：接続が意図しない要素へつながる。
  **原因の切り分け**：接続で表示ラベルを使っていないか、同じキーを別の要素に使っていないかを確認する。
  **次の確認**：キーを固有の短い識別子に戻し、`d2 validate architecture.d2` を実行する。
- **症状**：要素の境界が伝わらない。
  **原因の切り分け**：配置境界を単なるラベルで表している可能性がある。
  **次の確認**：境界に属する要素を container の中括弧へ移す。

### フロー図を作成する

#### 目的

開始から終了までの順序と分岐を確認できるフロー図を `.d2` と SVG で残す。

#### 前提条件

開始点、終了点、判断条件、分岐ごとの行き先を確定する。

例外処理の責任者や仕様が未確定なら、エラー経路を断定せず利用者に確認する。

#### 推奨コマンド

1. `direction: down` を指定して、上から下への流れを基本にする。
2. 開始と終了には `shape: oval`、判断には `shape: diamond` を使う。
3. 分岐する接続には短い判断結果のラベルを付ける。
4. `d2 validate flow.d2` を実行する。

```d2
direction: down

start: 開始 {
  shape: oval
}
validate: 入力を検証
valid: 有効か {
  shape: diamond
}
complete: 完了 {
  shape: oval
  style.fill: "#eaf7ea"
}
reject: 差し戻す {
  style.fill: "#fff0f0"
}

start -> validate -> valid
valid -> complete: はい
valid -> reject: いいえ
```

#### 結果の確認

`d2 validate flow.d2` が成功することを確認する。

SVG を生成した後、開始から各終了点まで追えること、判断の全分岐にラベルがあること、矢印の向きが手順と一致することを画像で確認する。

#### 停止条件

判断条件の意味、分岐の網羅性、または終了状態が不明な場合は、仮の分岐を確定した図として出力せず確認する。

#### 代表的な失敗

- **症状**：分岐の意味が SVG で判別できない。
  **原因の切り分け**：判断ノードだけに条件を書き、接続ラベルを省略している可能性がある。
  **次の確認**：各出力接続へ `はい`、`いいえ` などの結果ラベルを付ける。
- **症状**：手順が横方向へ広がり、開始と終了を追いにくい。
  **原因の切り分け**：全体の向きが用途に合っていない可能性がある。
  **次の確認**：`direction: down` を指定して再描画する。
