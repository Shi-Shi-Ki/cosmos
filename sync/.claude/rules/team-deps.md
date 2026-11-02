---
paths:
  - "**/package.json"
  - "**/pnpm-lock.yaml"
  - "**/package-lock.json"
  - "**/pnpm-workspace.yaml"
  - "**/.npmrc"
  - ".github/workflows/**"
owner: "@Shi-Shi-Ki"
last-reviewed: 2026-11-01
---
<!-- {{COSMOS_REPO}} で管理。このリポジトリでは編集しない -->
# 依存パッケージ（npm サプライチェーン対策）

乗っ取られたパッケージは、公開から数時間〜数日で見つかり削除されることが多い。その間に入れないこと、入れても install 時に実行させないことを優先する。

- 依存を追加・更新したら、lockfile の差分を確認し、頼んでいない間接依存の追加や、想定外のメジャー更新があれば報告する
- 新しい依存は、名前の打ち間違い（typosquatting）、公開日、メンテナ、週間ダウンロード数を確認してから追加を提案する
- install スクリプト（preinstall / postinstall）の実行を許可しない。pnpm 10 以降は `onlyBuiltDependencies` に追加する前に理由を示して確認を取る。npm は `.npmrc` の `ignore-scripts=true` を外さない
- 公開直後の版を入れない。pnpm 10.16 以降は `pnpm-workspace.yaml` の `minimumReleaseAge`（分）で遅らせる。緊急の脆弱性修正は `minimumReleaseAgeExclude` で個別に許可し、理由を残す
- CI では lockfile どおりにだけ入れる（pnpm: `pnpm install --frozen-lockfile`、npm: `npm ci`）。`--no-frozen-lockfile` や `npm install` に変えない
