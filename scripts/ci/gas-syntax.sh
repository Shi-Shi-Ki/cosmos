#!/usr/bin/env bash
# GAS のファイルの構文を調べる。入力: LIST（gas-files.sh が作ったファイル一覧）
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

node "$COSMOS_SCRIPTS/gas-syntax.cjs" "$LIST" 2>&1 | tee "$LOGS/gas-syntax.log"
