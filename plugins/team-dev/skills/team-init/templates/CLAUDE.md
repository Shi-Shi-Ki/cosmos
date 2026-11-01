# <プロジェクト名>

## 概要
- <何をするシステムか（1〜2 行）>
- 主要ディレクトリ: <例: src/（TS）, gas/（GAS）, infra/（Terraform）>

## バージョン
- <例: Node.js 22.x / TypeScript 5.x / pnpm 9.x>
- <例: GAS: V8 ランタイム, clasp 3.x>
- <例: Terraform 1.x（.terraform-version 参照）/ AWS provider 6.x / Google provider 7.x>
- <例: Next.js 15.x（App Router）>

## コマンド
- テスト: <例: `pnpm test`（単体: `pnpm test -- path/to/file`）>
- 型チェック: <例: `pnpm typecheck`>
- Lint: <例: `pnpm lint`>
- Terraform: <例: `terraform fmt -recursive && terraform validate && tflint`>

## 完了の定義
- 変更後に型チェック / lint / テストを実行し、すべて成功したことを報告する
- 失敗した場合はテストを削除・スキップせず、原因を報告する

## 禁止事項
- `terraform apply` / `clasp deploy` を実行しない（人間が行う）
- 新しい依存パッケージを追加する前に確認を取る
- 設計判断（ライブラリ選定、データモデル変更、アーキテクチャ変更）は実装前に選択肢を提示し、docs/adr/ に ADR の下書きを作る
- <例: AWS のリソースを変更しうるコマンド（create / update / delete / put / invoke / `ssm start-session` など）は、実行前にコマンドと影響範囲を提示して確認を取る。describe / list / get は確認なしで実行してよい。`--with-decryption` で SecureString を復号しない>
- <リポジトリ固有の禁止事項>

## プロジェクト固有の注意点
- <例: GAS は 6 分の実行時間制限があるため、バッチは分割して Trigger で継続する>
- <例: state は AWS: S3 backend（use_lockfile）/ GCP: GCS backend。環境は envs/{dev,stg,prd}>

## 参照
- チーム共通の規約: .claude/rules/team-*.md（中央リポジトリから同期。ここでは編集しない）
- このリポジトリ固有の規約: .claude/rules/local-*.md
- 設計判断の履歴: docs/adr/
