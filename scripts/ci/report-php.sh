#!/usr/bin/env bash
# PHP ジョブが失敗したときの PR コメントの文面（$LOGS/report.md）を作る。
# 入力: SYNTAX / VALIDATE / DEPS / AUDIT / LINT / TEST（各ステップの outcome）
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$COSMOS_SCRIPTS/lib.sh"
HITS_PATTERN='error|fail|warn|critical|high|severity|advisor|cve-'
version_note="" env_note=""
if [ -s "$LOGS/php-version.txt" ]; then
  version_note="（$(grep -oE 'PHP [0-9]+\.[0-9]+' "$LOGS/php-version.txt" | head -n 1)）"
  env_note=" 実行環境: $(cat "$LOGS/php-version.txt")"
fi
[ "$SYNTAX" = failure ] && section "PHP の構文$version_note" "$LOGS/php-syntax.log" \
  "抜粋の \`in <ファイル> on line <行>\` の箇所に構文エラーがあります。手元では \`php -l <ファイル>\` で確認できます。バージョンが違う場合は、composer.json の \`require.php\` を確認してください。$env_note"
[ "$VALIDATE" = failure ] && section "composer.json の検証" "$LOGS/php-validate.log" \
  "composer.json の書式か内容に誤りがあります。手元で \`composer validate\` を実行して直してください。"
[ "$DEPS" = failure ] && section "依存のインストール（composer）" "$LOGS/php-deps.log" \
  "composer.lock がないか、composer.json と一致していません。手元で \`composer install\`（依存を変えたなら \`composer update <パッケージ>\`）を実行し、更新された composer.lock をコミットしてください。"
[ "$AUDIT" = failure ] && section "既知の脆弱性（composer audit）" "$LOGS/php-audit.log" \
  "依存パッケージに公表済みの脆弱性があります。抜粋のパッケージを、修正されたバージョンに \`composer update <パッケージ>\` で上げてください。すぐに上げられない場合は、影響を確認して PR に理由を書いてください。"
[ "$LINT" = failure ] && section "リポジトリの lint（composer lint）$version_note" "$LOGS/php-lint.log" \
  "composer.json の \`scripts.lint\` が失敗しました。手元で \`composer lint\` を実行して直してください。$env_note"
[ "$TEST" = failure ] && section "リポジトリの test（composer test）$version_note" "$LOGS/php-test.log" \
  "composer.json の \`scripts.test\` が失敗しました。手元で \`composer test\` を実行して再現してください。CI では PHP の拡張モジュールが手元と違うことがあります。$env_note"
true
