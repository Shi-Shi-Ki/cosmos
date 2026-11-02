#!/usr/bin/env bash
# 追跡されている全 .php を php -l で調べる。1 つの構文エラーで止めず、すべてのファイルを調べる。
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

set +e
# 1 つの構文エラーで止めず、すべてのファイルを調べる
out=$(git ls-files -z '*.php' | xargs -0 -r -n 100 bash -c 'php-target -l "$@" || exit 1' _ 2>&1)
status=$?
set -e
printf '%s\n' "$out" | grep -v '^No syntax errors detected' | tee "$LOGS/php-syntax.log" || true
exit "$status"
