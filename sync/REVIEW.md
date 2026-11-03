<!-- {{COSMOS_REPO}} で管理。このリポジトリでは編集しない。固有の観点は .claude/rules/local-*.md かサブディレクトリの REVIEW.md に書く -->
# Review guidelines

## 重大度の定義
- Important は以下に限定する: 動作が壊れる / データ漏洩 / 権限昇格 /
  ロールバック不能な変更 / 本番リソースの意図しない削除・再作成
- スタイルや命名は Nit とし、最大 5 件まで
- 指摘には必ず file:line と、問題が起きる具体的な入力・状態を書く

## 基準の優先順位
- リポジトリ固有の基準（`.claude/rules/local-*.md`、サブディレクトリの REVIEW.md）が、
  この REVIEW.md や `team-*.md` と相反する場合は、リポジトリ固有の基準に従う
- ただし、例外として扱うのは次をすべて書いたものだけ。欠けていれば共通の基準に従い、Nit で不足を指摘する
  - 上書きする共通の基準（ファイル名と項目）
  - 範囲（`paths:` やディレクトリ）
  - 理由
  - 期限（期限を過ぎた例外は無効とし、Nit で削除を促す）
- 次の項目は例外を認めない: シークレット・個人情報の扱い、認可・権限、依存パッケージの安全性（依存パッケージの節）

## 必須チェック（全言語）
- 新しい API エンドポイントや公開関数に、入力検証と認可チェックがあるか
- SQL / シェル / HTML / テンプレートへの外部入力が、パラメータ化・エスケープされているか
- シークレット、トークン、個人情報がコード・ログ・エラーメッセージに含まれていないか
- 設計変更（依存追加、スキーマ変更、アーキテクチャ変更）に対応する docs/adr/ があるか
- docs/adr/ の status が accepted なのに「決定」欄が空のものは Important
- 振る舞いを変える変更にテストが追加されているか

## 依存パッケージ（package.json、lockfile、.npmrc、pnpm-workspace.yaml の変更のみ）
- lockfile に、package.json の変更から説明できない新しいパッケージが増えているものは Important
- install スクリプトの許可（onlyBuiltDependencies への追加、ignore-scripts の解除）は Important
- `minimumReleaseAge` の削除・短縮、CI の `--frozen-lockfile` / `npm ci` の解除は Important

## Terraform（*.tf の変更のみ）
- IAM の Action / Resource のワイルドカード、0.0.0.0/0 の ingress、public なバケットは Important
- lifecycle / moved なしのリソース名変更は Important（再作成が起きるため）
- provider / module のバージョン未固定は Important

## GAS（*.gs、appsscript.json の変更のみ）
- ループ内のサービス呼び出し（getRange / setValue など）は指摘する
- appsscript.json の oauthScopes 拡大は Important

## シェルスクリプト（*.sh の変更のみ）
- 変数のクォート漏れ、`set -euo pipefail` 相当のエラー処理の欠如は指摘する
- 外部入力を eval / コマンド置換に渡しているものは Important

## 指摘しないもの
- 生成ファイル（dist/, *.gen.ts）、.terraform.lock.hcl
- lockfile の 1 行ずつの内容（依存パッケージの節で見るのは、パッケージの増減と版の変化だけ）
- formatter / linter が検出する内容（CI で担保済み）
