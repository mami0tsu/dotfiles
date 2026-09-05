# digest-json

JSONをkeyの辞書順、余分な空白なし、末尾LFが1つのUTF-8表現へ正規化する。
正規化後のbyte列からSHA-256 digestを求める。

入力fileを使う場合は、通常fileであることと、groupおよびotherへ読取権限がないことを確認する。
標準入力を使う場合も、JSONをcommand line argumentへ含めない。

```sh
bash "<plugin-root>/skills/tool-artifact-digest/scripts/artifact-digest.sh" json --file <private-json-file>
```

`--file`を省略すると標準入力を読む。
Objectのkey順と整形だけを正規化し、arrayの順序や文字列値は変更しない。
出力された`sha256:<digest>`を、その正規化済みJSONのdigestとして扱う。
