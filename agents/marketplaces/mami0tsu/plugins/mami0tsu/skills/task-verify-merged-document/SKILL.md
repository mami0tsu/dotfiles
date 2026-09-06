---
name: task-verify-merged-document
description: >-
  設計Documentのpull requestがmerge済みであることを確認し、merge済み本文のURL、revision、digestを取得するTask。
  Git管理Documentを設計正本として確定するときに使う。
allowed-tools: >-
  Read
  Skill(mami0tsu:tool-artifact-digest)
  Skill(mami0tsu:tool-gh)
  Skill(mami0tsu:tool-git)
---

# task-verify-merged-document

pull requestとmerge先のDocumentを取得し、実装Issueが参照できる正本を確定する。
pull request上の人間による編集はmerge済み本文へ反映し、その内容を最終承認として扱う。

## 入力

- Draft PRのURL、Document変更結果、Draft PR作成計画、merge確認計画、成果物の承認結果、承認済みoperation envelope、merge確認のpending operation
- またはhost、repository、path、revision、merge先branchを含む正本Git Documentの参照

## 出力

- merge済みDocument

## 制約

- pull request、branch、commit、Documentを変更しない。
- open、closed、未mergeのpull requestを成功扱いにしない。
- merge先のpathがDocument変更結果と異なる場合は停止する。
- Pull request経路では、承認済みoperation envelope、承認結果、pending operationのoperation IDとdigestが一致しない場合は停止する。
- Merge確認計画が承認済みoperation envelopeの反映値と同一でない場合は停止する。
- Pull requestのrepository、base branch、head branch、Document pathが承認済み計画と異なる場合は停止する。
- merge済み本文を承認前の本文へ戻さない。

## 手順

### 1. Pull requestを取得する

Draft PRのURLが入力された場合は、承認済みoperation envelope全体を共通のJSON digest操作へ渡し、そのoperation IDとdigestが成果物の承認結果およびpending operationと一致することを確認する。
Merge確認計画がoperation envelopeの反映値と同一であることを確認する。
Pull requestを取得し、host、repository、base、head、merge状態、merge commit、Document pathを承認済み計画と照合する。
Merge commitが承認済みbase branchから到達可能であることを確認する。
正本Git Documentの参照が入力された場合は、記録されたhost、repository、path、revisionを使い、revisionがmerge先から到達可能であることを確認する。
Local checkoutを利用できない場合は、記録されたhostの認証済みremoteでrevisionと記録済みmerge先branchを比較し、merge先branchがrevisionを含むことを確認する。
記録済みmerge先branchがない場合や、別branchからしか到達できない場合は停止する。

### 2. Documentを取得する

確認済みrevisionで指定pathのDocumentを取得する。
正本repositoryのlocal checkoutを利用できない場合は、正本参照にあるhost、canonical repository、完全なcommit OID、pathを使い、認証済みremoteから本文を取得する。
pathとblobの一方でも存在しない場合は停止する。

### 3. 正本情報を作る

Pull requestのURLから確認した場合はmerge commitをrevisionとする。
正本Git Documentの参照から確認した場合は、merge先からの到達可能性を確認した記録済みrevisionを使う。
確定したrevisionでcommitを固定したfile URLを求める。
取得した本文を共通のtext digest操作へ渡し、他の正本経路と同じ本文digestを求める。

### 4. 結果を返す

host、repository、path、merge先branch、正本URL、revision、本文digest、merge済み本文をmerge済みDocumentとして返す。
