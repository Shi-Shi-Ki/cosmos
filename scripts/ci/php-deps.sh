#!/usr/bin/env bash
# composer.lock どおりに依存を入れる。プラグインとインストール時のスクリプトは実行しない（サプライチェーン対策）。
# パッケージがあるのに composer.lock がなければ失敗する。出力（GITHUB_OUTPUT）: installed
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

if [ -f composer.lock ]; then
  composer install --no-interaction --no-progress --no-plugins --no-scripts --prefer-dist --ignore-platform-reqs 2>&1 | tee "$LOGS/php-deps.log"
  echo "installed=true" >> "$GITHUB_OUTPUT"
elif jq -e '[(.require // {}), (."require-dev" // {}) | keys[] | select(test("^(php|ext-|lib-|composer)") | not)] | length > 0' composer.json >/dev/null; then
  echo "composer.lock がありません" | tee "$LOGS/php-deps.log"
  echo "::error::composer.lock がありません（composer install で作り、コミットしてください）"
  exit 1
else
  echo "依存パッケージがないため飛ばします"
  echo "installed=true" >> "$GITHUB_OUTPUT"
fi
