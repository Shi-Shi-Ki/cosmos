#!/usr/bin/env bash
# state・変数ファイル・.env など、コミットしてはいけないファイルが追跡されていないかを調べる。
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

found=$(git ls-files '*.tfstate' '*.tfstate.*' '*.tfvars' '.env' '.env.*' '.clasprc.json' '*/.clasprc.json' | grep -vE '(^|/)\.env\.example$' || true)
if [ -n "$found" ]; then
  printf '%s\n' "$found" > "$LOGS/tracked.txt"
  echo "::error::コミットしてはいけないファイルがあります: $found"
  exit 1
fi
