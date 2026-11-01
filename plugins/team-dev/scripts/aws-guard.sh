#!/usr/bin/env bash
# Bash ツールで実行される aws コマンドを調べ、参照系以外なら実行前にユーザーの承認を求める。
# settings.json の deny / allow はコマンド文字列のパターン照合なので、`bash -c "..."` や
# `aws --profile x ...` の形ですり抜ける。ここでは区切り記号と引用符をはずしてから判定する。
# 判定に迷ったものは承認を求める側に倒す。
set -uo pipefail

cmd=$(jq -r '.tool_input.command // empty')
[ -n "$cmd" ] || exit 0

respond() { # $1: ask | deny, $2: 理由
  jq -n --arg d "$1" --arg r "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
  exit 0
}

# 区切り記号を「;」の単独トークンにし、引用符をはずして、ラッパー（bash -c "..." など）の中も同じ列に並べる
flat=$(printf '%s' "$cmd" | sed -e 's/[;&|()`{}<>]/ ; /g' -e "s/[\"'\\$]/ /g" | tr '\n\t' ';;' | sed 's/;/ ; /g')
read -r -a words <<<"$flat"

# aws の直前に来てもよいもの（コマンドの先頭として扱う）
prefixes=" ; -c sudo env time exec nohup command eval xargs nice timeout watch "

# 値を取る aws のグローバルオプション
value_opts=" --profile --region --output --endpoint-url --query --color --ca-bundle \
--cli-read-timeout --cli-connect-timeout --cli-binary-format "

# 参照系だが、秘密情報や認証情報を返すもの（承認を求める）
sensitive=" secretsmanager:get-secret-value ecr:get-login-password ecr-public:get-login-password \
sts:get-session-token sts:get-federation-token codeartifact:get-authorization-token \
cognito-identity:get-credentials-for-identity sso:get-role-credentials "

found=0
reasons=()
n=${#words[@]}
for ((i = 0; i < n; i++)); do
  w=${words[i]}
  [ "$w" = aws ] || [[ "$w" == */aws ]] || continue
  # コマンドの先頭にある aws だけを見る（`grep aws src/` などは対象外）
  k=$((i - 1))
  while ((k >= 0)) && [[ "${words[k]}" == *=* || "${words[k]}" =~ ^-[a-zA-Z0-9]+$ && ! "${words[k]}" =~ c$ || "${words[k]}" =~ ^[0-9]+[smhd]?$ ]]; do
    ((k--))
  done
  ((k < 0)) || [[ "$prefixes" == *" ${words[k]} "* || "${words[k]}" =~ ^-[a-z]*c$ ]] || continue
  found=1

  # グローバルオプションを飛ばして、サービスと操作を取り出す
  service="" op=""
  for ((j = i + 1; j < n; j++)); do
    t=${words[j]}
    if [ "$t" = ";" ]; then
      break
    elif [[ "$t" == --*=* ]]; then
      continue
    elif [[ "$value_opts" == *" $t "* ]]; then
      ((j++))
    elif [[ "$t" == -* ]]; then
      continue
    elif [ -z "$service" ]; then
      service=$t
    else
      op=$t
      break
    fi
  done

  # `aws --version` や `aws help` は参照系
  [ -z "$service" ] && continue
  [ "$service" = help ] && continue

  case "$service:$op" in
    s3:ls | logs:tail | *:help | configure:list | configure:get) continue ;;
  esac
  if [[ "$sensitive" == *" $service:$op "* ]]; then
    reasons+=("aws $service $op は秘密情報・認証情報を返します")
  elif [[ "$op" =~ ^(describe|list|get|batch-get|filter|lookup|search)- ]]; then
    continue
  else
    reasons+=("aws $service ${op:-（操作不明）} はリソースを変更する可能性があります")
  fi
done

[ "$found" = 1 ] || exit 0

# SecureString の復号は承認ではなく拒否する
if [[ " $flat " == *" --with-decryption"* ]]; then
  respond deny "--with-decryption による SecureString の復号は禁止されています（CLAUDE.md の禁止事項）。値が必要なら人間が取得してください。"
fi

if [ ${#reasons[@]} -gt 0 ]; then
  msg=$(printf '%s / ' "${reasons[@]}")
  respond ask "${msg% / }。実行してよいか、コマンドと影響範囲を確認してください。"
fi
exit 0
