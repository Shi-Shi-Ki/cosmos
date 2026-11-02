#!/usr/bin/env bash
# 各ジョブの失敗のまとめ（reports/*/report.md）を 1 つの PR コメントにして作成・更新する。
# 次の実行で成功したら、同じコメントを「解消しました」に書き換える。
# 入力: GH_TOKEN / REPO / PR / SHA / RUN_URL / FAILED
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

marker='<!-- cosmos-ci-report -->'
existing=$(gh api "repos/$REPO/issues/$PR/comments" --paginate --jq ".[] | select(.user.type == \"Bot\" and (.body | startswith(\"$marker\"))) | .id" | tail -n 1)
body="$RUNNER_TEMP/body.md"
if [ "$FAILED" = true ]; then
  {
    echo "$marker"
    echo "## CI が失敗しました（${SHA:0:7}）"
    echo
    find reports -name report.md -exec cat {} + 2>/dev/null
    if ! find reports -name report.md 2>/dev/null | grep -q .; then
      echo "失敗したチェックのまとめを作れませんでした（タイムアウトや取り消しなど）。[実行ログ]($RUN_URL) を確認してください。"
      echo
    fi
    echo "---"
    echo "直したら push すると、CI が再実行されてこのコメントが更新されます。直し方がわからないときは、この PR に \`@claude fix CI の失敗を直して\` とコメントすると修正 PR が作られます。 [実行ログ]($RUN_URL)"
  } > "$body"
elif [ -n "$existing" ]; then
  printf '%s\n## CI の失敗は解消しました（%s）\n\nすべてのチェックが成功しています。 [実行ログ](%s)\n' "$marker" "${SHA:0:7}" "$RUN_URL" > "$body"
else
  exit 0
fi
if [ -n "$existing" ]; then
  gh api -X PATCH "repos/$REPO/issues/comments/$existing" -F body=@"$body" >/dev/null
else
  gh api -X POST "repos/$REPO/issues/$PR/comments" -F body=@"$body" >/dev/null
fi || echo "::warning::PR にコメントできませんでした。team-ci.yml の permissions に pull-requests: write があるか確認してください。"
