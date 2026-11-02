#!/usr/bin/env bash
# aws-guard.sh の単体テスト。cases.tsv の各コマンドを hook に渡し、判定が期待どおりかを確かめる。
set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
guard="$here/../../plugins/team-dev/scripts/aws-guard.sh"
pass=0 fail=0
while IFS=$'\t' read -r expected cmd; do
  case "$expected" in ''|'#'*) continue ;; esac
  out=$(jq -n --arg c "$cmd" '{tool_name: "Bash", tool_input: {command: $c}}' | bash "$guard")
  actual=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)
  actual=${actual:-allow}
  if [ "$actual" = "$expected" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'NG  期待 %-5s 実際 %-5s  %s\n' "$expected" "$actual" "$cmd"
  fi
done <"$here/cases.tsv"
echo "aws-guard: ${pass} 件成功, ${fail} 件失敗"
[ "$fail" -eq 0 ]
