#!/usr/bin/env bash
# GAS ジョブが失敗したときの PR コメントの文面（$LOGS/report.md）を作る。
# 入力: SYNTAX（構文チェックの outcome）
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

out="$LOGS/report.md"
if [ "$SYNTAX" = failure ]; then
  {
    echo "### ❌ GAS の構文"
    echo
    echo "抜粋の \`<ファイル>:<行>\` の箇所に構文エラーがあります。GAS では、1 つのファイルの構文エラーでプロジェクト全体が動かなくなります。括弧や引用符の閉じ忘れ、\`import\` / \`export\`（GAS では使えません）がないか確認してください。"
    echo
    echo '```'
    grep -v 'ファイルを確認し' "$LOGS/gas-syntax.log" | head -n 40 || true
    echo '```'
    echo
  } >> "$out"
fi
true
