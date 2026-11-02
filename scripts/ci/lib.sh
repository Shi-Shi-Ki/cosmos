#!/usr/bin/env bash
# 失敗コメントを作るスクリプト（report-*.sh）が共通で使う関数。

# section <見出し> <ログ> <対応方法>
# $LOGS/report.md に 1 つのチェックの説明を追記する。ログがあれば、HITS_PATTERN に合う行（なければ末尾 20 行）を抜粋として載せる。
section() {
  local out="$LOGS/report.md" clean hits
  {
    echo "### ❌ $1"
    echo
    echo "$3"
    echo
    if [ -s "$2" ]; then
      echo '<details><summary>エラーの抜粋</summary>'
      echo
      echo '```'
      clean=$(sed 's/\x1b\[[0-9;]*m//g' "$2")
      hits=$(printf '%s\n' "$clean" | grep -E -i "${HITS_PATTERN:-error|fail}" || true)
      if [ -n "$hits" ]; then printf '%s\n' "$hits" | head -n 40; else printf '%s\n' "$clean" | tail -n 20; fi
      echo '```'
      echo '</details>'
      echo
    fi
  } >> "$out"
}
