---
paths:
  - "**/*.ts"
  - "**/*.tsx"
owner: "@Shi-Shi-Ki"
last-reviewed: 2026-10-31
---
<!-- Shi-Shi-Ki/cosmos で管理。このリポジトリでは編集しない -->
# TypeScript

- `any` を使わない。型が分からない外部データは `unknown` で受け、スキーマ検証（zod など）で型を絞る
- `as` による型アサーションは、理由をコメントで残せる場合だけ使う
- 非同期処理の Promise は必ず await するか、意図的に待たない場合は `void` を付けて明示する
- エラーを握りつぶさない。catch した場合は再 throw するか、ログに文脈を付けて残す
