# 検証記録

## 2026-08-23

### 構造と文章

- `quick_validate.py`：frontmatter、Skill 名、description、resource 構造の検証に成功した。
- `textlint`：`README.md`、`SKILL.md`、全 reference の検査に成功した。
- `yamllint --strict`：`agents/openai.yaml` の検査に成功した。
- `git diff --check`：空白 error がないことを確認した。

### Agent シナリオ試験

3つの独立した sub-agent が、仕様と状態遷移、security、Skill の実行可能性を担当した。

各 sub-agent には P-100、base と target、対象差分、担当観点だけを渡し、file と外部状態の変更を禁止した。

次のシナリオを手順の分岐に沿って追跡した。

- 他人の単一 PR：base と head の OID を固定し、2つ以上の専門観点から pending review まで進める。
- stacked PR：親 branch だけが更新された場合も base OID の不一致で書き込みを止める。
- 自己 PR：pending review を作る前に認証利用者と author の一致で停止する。
- 未信頼の差分：sub-agent の tool 利用を禁止し、PR 内の命令に従わない。
- finding なし：選定理由と検証範囲を review body に残す。
- mutation 中の head 更新：次の mutation または引き渡し前に OID の不一致で停止する。
- 既存 pending review：workflow state と一致しない review を変更しない。
- 人間の submit 待ち：pending の間は workflow state を保持し、同じ review ID を再開時に照合する。
- submit 後の merge または close：PR の状態にかかわらず、同じ review ID の submit を read-only で確認して state を完了する。

初回試験では、base OID の再照合、mutation ごとの OID 確認、pending 中の state 保持、Claude Code sub-agent の tool 禁止が不足していた。

再試験では、sub-agent の全 tool 禁止と submit 後に PR が merge または close された経路を追加で修正した。
