#!/usr/bin/env bash
# TypeScript ジョブが失敗したときの PR コメントの文面（$LOGS/report.md）を作る。
# 入力: DEPS / TSC / ESLINT / PRETTIER / TEST（各ステップの outcome）、RUN / X（pnpm か npm か）
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$COSMOS_SCRIPTS/lib.sh"
HITS_PATTERN='error|fail|warn|✕|●|\[warn\]'
[ "$DEPS" = failure ] && section "依存のインストール" "$LOGS/deps.log" \
  "lockfile と package.json が一致していないか、lockfile がありません。手元で \`$RUN install\` を実行し、更新された lockfile をコミットしてください。"
[ "$TSC" = failure ] && section "型チェック（tsc）" "$LOGS/tsc.log" \
  "抜粋の \`ファイル(行,列): error TSxxxx\` の箇所を直してください。手元では \`$X tsc --noEmit\` で確認できます。\`Cannot find module\` は import のパスか、依存の入れ忘れが原因のことが多いです。"
[ "$ESLINT" = failure ] && section "Lint（ESLint）" "$LOGS/eslint.log" \
  "手元で \`$X eslint . --fix\` を実行すると、自動で直せるものは直ります。残ったものは抜粋のルール名を見て手で直してください。"
[ "$PRETTIER" = failure ] && section "Format（Prettier）" "$LOGS/prettier.log" \
  "手元で \`$X prettier --write \"**/*.{ts,tsx,js,jsx,mjs,cjs}\"\` を実行し、結果をコミットしてください。"
[ "$TEST" = failure ] && section "テスト" "$LOGS/test.log" \
  "手元で \`$RUN test\` を実行して、失敗しているテストを再現してください。仕様を変えた場合はテストを直し、そうでなければ実装を直します。"
true
