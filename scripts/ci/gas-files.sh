#!/usr/bin/env bash
# GAS として構文を調べるファイルを集める: .gs と、appsscript.json のあるディレクトリの .js。
# 出力（GITHUB_OUTPUT）: found、list（ファイル一覧のパス）
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

list="$RUNNER_TEMP/gas-files.txt"
{
  git ls-files '*.gs'
  git ls-files '*appsscript.json' | while read -r manifest; do
    dir=$(dirname "$manifest")
    if [ "$dir" = . ]; then git ls-files '*.js'; else git ls-files "$dir/*.js"; fi
  done
} | sort -u > "$list"
if [ -s "$list" ]; then echo "found=true" >> "$GITHUB_OUTPUT"; fi
echo "list=$list" >> "$GITHUB_OUTPUT"
