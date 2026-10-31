#!/usr/bin/env bash
# Claude が編集したファイルを拡張子に応じて整形する。
# 整形ツールが入っていない環境では何もしない（編集自体は止めない）。
set -uo pipefail

file=$(jq -r '.tool_input.file_path // empty')
[ -n "$file" ] && [ -f "$file" ] || exit 0

case "$file" in
  *.ts|*.tsx|*.js|*.jsx|*.vue|*.gs|*.json|*.md)
    if [ -x node_modules/.bin/prettier ]; then
      node_modules/.bin/prettier --write --log-level warn "$file"
    fi
    case "$file" in
      *.ts|*.tsx|*.js|*.jsx|*.vue|*.gs)
        if [ -x node_modules/.bin/eslint ]; then
          node_modules/.bin/eslint --fix "$file" >/dev/null 2>&1 || true
        fi
        ;;
    esac
    ;;
  *.tf|*.tfvars)
    if command -v terraform >/dev/null 2>&1; then
      terraform fmt "$file" >/dev/null
    fi
    ;;
  *.sh)
    if command -v shfmt >/dev/null 2>&1; then
      shfmt -w "$file"
    fi
    ;;
esac
exit 0
