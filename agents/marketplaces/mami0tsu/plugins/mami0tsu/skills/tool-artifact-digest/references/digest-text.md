# digest-text

UTF-8 textのCRLFとCRをLFへ変換し、末尾のLFをちょうど1つにそろえる。
正規化後のbyte列からSHA-256 digestを求める。

入力fileを使う場合は、通常fileであることと、groupおよびotherへ読取権限がないことを確認する。
標準入力を使う場合も、本文をcommand line argumentへ含めない。

```sh
bash "<plugin-root>/skills/tool-artifact-digest/scripts/artifact-digest.sh" text --file <private-text-file>
```

`--file`を省略すると標準入力を読む。
出力された`sha256:<digest>`を、その正規化済み本文のdigestとして扱う。
