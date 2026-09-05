# remove-private-body

## 目的

GitHub操作の成否にかかわらず、専用scriptが作った一時body fileを削除する。

## 前提条件

- `prepare-private-body`が返した絶対path

## 推奨コマンド

```sh
bash "<plugin-root>/skills/tool-gh/scripts/private-body-file.sh" remove --file <private-body-file>
```

専用directoryとbody fileが検査に通った場合だけ削除する。
検査に失敗したpathを別の削除commandへ渡さない。
