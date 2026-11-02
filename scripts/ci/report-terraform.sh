#!/usr/bin/env bash
# Terraform ジョブが失敗したときの PR コメントの文面（$LOGS/report.md）を作る。
# 入力: FMT / VALIDATE（各ステップの outcome）、DIR（Terraform のディレクトリ）
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

out="$LOGS/report.md"
if [ "$FMT" = failure ]; then
  {
    echo "### ❌ Terraform fmt"
    echo
    echo "次のファイルの書式が揃っていません。\`cd $DIR && terraform fmt -recursive\` を実行し、結果をコミットしてください。"
    echo
    echo '```'
    head -n 40 "$LOGS/fmt.log"
    echo '```'
    echo
  } >> "$out"
fi
if [ "$VALIDATE" = failure ]; then
  {
    echo "### ❌ Terraform validate"
    echo
    echo "構文・参照・型の誤りがあります。抜粋の \`Error:\` と \`on <ファイル> line <行>\` の箇所を直してください。手元では \`cd $DIR && terraform init -backend=false && terraform validate\` で確認できます。"
    echo
    echo '<details><summary>エラーの抜粋</summary>'
    echo
    echo '```'
    grep -A6 -E '^(Error|│ Error)' "$LOGS/validate.log" | head -n 40 || true
    echo '```'
    echo '</details>'
    echo
  } >> "$out"
fi
true
