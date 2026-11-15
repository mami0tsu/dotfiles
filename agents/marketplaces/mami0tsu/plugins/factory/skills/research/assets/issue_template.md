{# labels: idea #}

{# 文章と箇条書きは体言止めを使わず、終止形で書く。 #}
{# 表を使う対象以外のセクションでは、同列の情報を比較または列挙するときは箇条書きにする。 #}

## 概要

{# 何を対象に何をするアイデアかを一言で示す。 #}
{{ summary }}

## 背景

{# 現状と改善が必要な理由を示す。 #}
{{ background }}

## 対象

### リポジトリ

{# 対象リポジトリを name、url、description を持つ配列で指定する。 #}
| リポジトリ | 対象となる理由 |
| --- | --- |
{% for item in repositories %}
| [{{ item.name }}]({{ item.url }}) | {{ item.description }} |
{% endfor %}

### ファイル

{# 対象ファイルを name、パーマネントリンクの url、description を持つ配列で指定する。 #}
| ファイル | 対象となる理由 |
| --- | --- |
{% for item in files %}
| [{{ item.name }}]({{ item.url }}) | {{ item.description }} |
{% endfor %}

## やること

{# 実現したいことと、改善に含める作業を配列で指定する。 #}
{% for item in in_scope %}
- {{ item }}
{% endfor %}

## やらないこと

{# 今回の改善に含めない作業を配列で指定する。 #}
{% for item in out_of_scope %}
- {{ item }}
{% endfor %}

## リスク

{# 改善によって影響を受ける対象、懸念される問題、確認できていないことを配列で指定する。 #}
{% for item in risks %}
- {{ item }}
{% endfor %}
