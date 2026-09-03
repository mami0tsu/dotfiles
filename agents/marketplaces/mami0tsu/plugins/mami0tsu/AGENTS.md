# AGENTS.md

## 設計原則

`mami0tsu` pluginは、ソフトウェア開発工程をWorkflow、Step、Taskの3階層へ分け、具体的な実現方法をToolへ隔離する。

- 新しい処理を追加する前に、その処理を担当する階層を決める。
- 一つのSkillが複数の責任を持つ場合は、Skillを分ける。
- 上位のSkillは、下位のSkillが返す出力だけを受け取り、下位のSkillが使うresourceを参照しない。

### 責務

| 階層 | 責務 | 依存先 |
| --- | --- | --- |
| Workflow | Stepの順序と入出力の受け渡しを管理し、外部から受け取った入力を最終出力へ変換する。 | Step |
| Step | Taskを組み合わせ、詳細な開始条件、停止条件、再実行を管理する。 | Task |
| Task | 一つの行動を実行し、その行動に直接必要な入力から成果物を作る。 | Tool |
| Tool | CLIや外部サービスなど、特定の実現方法に依存する操作を扱う。 | reference、asset、script、別のTool |

### 制約

- WorkflowはTaskやToolを直接参照しない。
- Workflowは成果物の内容を検査せず、Stepの出力を解釈し直さない。
- StepはToolやToolのresourceを直接参照しない。
- Stepは、後続のTaskを安全に開始するために必要な条件を確認する。
- Taskは必要な操作と期待する出力を記述し、具体的なToolの選択をToolへ委ねる。
- Taskは具体的なTool名、ユースケース名、command、option、認証方法、Tool固有の状態を記述しない。
- 工程の成果物として必要な用語は、Taskの意味上の入出力として記述してよい。
- Toolのdescriptionは、必要な操作から選択できるように書く。
- Toolが別のToolへ操作を委譲する場合は、委譲先の操作を重複して記述しない。
- 制約はそのSkillの責任に限定し、下位のSkillが扱う制約を重複させない。

## 入出力

- Workflowの入力と出力には、pluginの外部から受け取る成果物とpluginの外部へ返す成果物だけを書く。
- Stepの入力と出力には、Taskを開始するために必要な成果物と、上位へ返す成果物だけを書く。
- Taskの入力には行動を開始するために必要な成果物だけを書く。
- Taskの出力には行動が直接作る成果物だけを書く。
- 実現方法に依存する途中の状態を、Workflow、Step、Taskの入出力へ含めない。

## Skill名

- Workflowは`workflow-{{verb}}`とする。
- Stepは`step-{{verb}}-{{object}}`とする。
- Taskは`task-{{verb}}-{{object}}`とする。
- Toolは`tool-{{tool-name}}`とする。
- `verb`には行動を表す動詞を使う。
- StepとTaskの名前は、具体的な実現方法ではなく、達成する行動を表す。
- 階層のprefixを除いた同じ名前を、別の階層で使い回さない。
- Skill名、directory名、frontmatterの`name`、最初の見出しを一致させる。
- Skill名とTool名は英小文字のkebab-caseで書く。
- 製品名、サービス名、command名、規格名は、それぞれの正式な表記を維持する。
- 同じ名前が異なる対象を表す場合は、大文字と小文字を含む正式な表記で対象を区別する。

## frontmatter

- `description`と`allowed-tools`には`>-`を使う[^claude-code-skills][^yaml-block-scalars]。
- `description`は一文ごとに行を分ける。
- `allowed-tools`は1行につき1つのToolを記述する。
- `allowed-tools`のToolはアルファベット順に並べる。

## Workflow、Step、Taskの構成

- 本文のセクションは次の構成に固定し、別のセクションを追加しない。

```md
# {{skill-name}}

{{description with paragraph writing}}

## 入力

## 出力

## 制約

## 手順

### {{通し番号}}. {{作業名}}
```

- 手順の見出しには、行動を表す動詞を使う。
- Skillを参照するときは、必ず「`{{skill-name}}`スキル」と書く。
- 「Taskスキル」のように階層名を一般名詞として付けない。

## Toolの構成

- Toolの本文は次の構成に固定し、別のセクションを追加しない。

```md
# {{skill-name}}

## 制約

## ユースケース
```

- ユースケースは関心ごとにMarkdown tableへ分ける。
- 各tableのユースケースは、ユースケース名のアルファベット順に並べる。
- SKILL.mdへcommandの詳細を書かず、対応するreferenceへ置く。

## Toolのresource

- referenceは一つのユースケースだけを扱う。
- referenceのファイル名は`{{verb}}-{{object}}.md`とする。
- 一つのreference内で処理を分岐させない。
- 分岐が必要な場合は、責任が異なるユースケースとしてreferenceを分ける。
- scriptはshell scriptだけとする。
- scriptはreferenceから呼び出し、SKILL.mdにScriptセクションを作らない。
- assetは出力へ転記または複製するテンプレートに使う。
- AI向けの指示には、ファイル形式に適したcommentを使う。
- 特定versionだけを許可する制約や、versionが一致しない場合の停止条件を追加しない。

## 文章

- 日本語は一文ごとに改行する。
- 段落の区切り以外に連続した空行を入れない。
- 並列または比較のために同じ粒度の情報を並べる場合は、箇条書きまたは順序付き箇条書きを使う。
- 想定する読み手に通じる一般的な用語を使う。
- 一般的でない用語が必要な場合は、初出時に意味を説明する。
- 具体的な数値または仕様を記述する場合は、出典を脚注で示すか、出典を明記した引用を添える。
- 脚注の参照用記述は、対応する文の句点の直前に置く。
- 出典を確認できない数値または仕様は、確定事項として記述しない。
- 同じ規則や説明を、SKILL.mdとreferenceの両方へ重複して書かない。

## 変更時の確認

- Skillの入出力を変更した場合は、その出力を受け取る上位Skillと、その入力を作る下位Skillを同じ変更で確認する。
- Workflow、Step、Taskを変更した場合は、階層を越えた参照とTool固有の知識が混入していないか確認する。
- Toolを変更した場合は、ユースケースとreferenceが一対一で対応しているか確認する。

[^claude-code-skills]: [Extend Claude with skills](https://code.claude.com/docs/en/slash-commands)
[^yaml-block-scalars]: [YAML 1.2.2 specification: Block Scalar Styles](https://yaml.org/spec/1.2.2/#81-block-scalar-styles)
