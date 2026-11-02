#!/usr/bin/env bash
# 秘密情報のジョブが失敗したときの PR コメントの文面（$LOGS/report.md）を作る。秘密情報の値は載せない。
# 入力: TRACKED / GITLEAKS（各ステップの outcome）、カレントディレクトリの results.sarif（gitleaks の結果）
# ci.yml から呼ばれる。LOGS（ログの置き場所）と COSMOS_SCRIPTS（このディレクトリ）は ci.yml が設定する。
set -eo pipefail

out="$LOGS/report.md"
if [ "$TRACKED" = failure ]; then
  {
    echo "### ❌ コミットしてはいけないファイル"
    echo
    echo "state・変数ファイル・.env には、平文の秘密情報が入ります。次を行ってください。"
    echo
    echo "1. \`git rm --cached <ファイル>\` で追跡から外し、\`.gitignore\` に入っているか確認してコミットする（手元のファイルは消えません）。"
    echo "2. 中に秘密情報（トークン・パスワード・鍵）が入っていた場合は、その値を無効化して作り直す。履歴に残るため、外すだけでは足りません。"
    echo
    echo '```'
    head -n 20 "$LOGS/tracked.txt"
    echo '```'
    echo
  } >> "$out"
fi
if [ "$GITLEAKS" = failure ]; then
  {
    echo "### ❌ 秘密情報らしき文字列（gitleaks）"
    echo
    echo "| ルール | ファイル:行 | コミット |"
    echo "| --- | --- | --- |"
    if [ -f results.sarif ]; then
      jq -r '.runs[0].results[] | "| \(.ruleId) | `\(.locations[0].physicalLocation.artifactLocation.uri):\(.locations[0].physicalLocation.region.startLine)` | \((.partialFingerprints.commitSha // "")[0:7]) |"' results.sarif | head -n 20
    else
      echo "| （詳細は Actions の Summary を参照） | | |"
    fi
    echo
    echo "- **本物の秘密情報の場合:** すぐにその値を無効化して作り直してください。ファイルから消しても、過去のコミットに残ります。"
    echo "- **誤検知の場合**（サンプル値・テンプレートのダミーなど）: その行を消すか、Actions の Summary にある Fingerprint をリポジトリ直下の \`.gitleaksignore\` に 1 行で追加してください。"
    echo
  } >> "$out"
fi
true
