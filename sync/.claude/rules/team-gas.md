---
paths:
  - "**/*.gs"
  - "**/appsscript.json"
  - "**/.clasp.json"
owner: "@Shi-Shi-Ki"
last-reviewed: 2026-10-31
---
<!-- Shi-Shi-Ki/cosmos で管理。このリポジトリでは編集しない -->
# Google Apps Script

- スプレッドシートの読み書きはループ内で行わず、`getValues()` / `setValues()` で一括処理する
- 6 分の実行時間制限を超えうる処理は、進捗を PropertiesService に保存し、時間主導型トリガーで分割して継続する
- シークレットはスクリプトプロパティに置き、コードに書かない
- `appsscript.json` の oauthScopes は必要最小限にし、追加する場合は理由を PR に書く
- ファイル間で関数名が衝突しないよう、グローバル関数にはファイル単位の接頭辞を付ける
