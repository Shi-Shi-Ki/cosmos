---
name: team-init
description: リポジトリにチーム標準の CLAUDE.md と .claude/settings.json を作成・更新する。新しいリポジトリの導入時や、バージョン情報を更新したいときに使う。
disable-model-invocation: true
---

# team-init

このリポジトリ固有の CLAUDE.md と `.claude/settings.json` を、チームで決めた形で作ります。
共通の規約（`.claude/rules/team-*.md`）と REVIEW.md は中央リポジトリから同期されるので、ここでは書きません。

## 手順

1. 次のファイルを読み、使っている言語・フレームワーク・ツールとそのバージョンを調べる。
   - `package.json`、ロックファイル（`pnpm-lock.yaml` / `package-lock.json` / `yarn.lock`）、`.nvmrc`、`.node-version`
   - `tsconfig.json`
   - `.clasp.json`、`appsscript.json`
   - `.terraform-version`、`*.tf` の `required_version` と `required_providers`
   - `.github/workflows/*.yml`（テスト・lint・ビルドのコマンド）
2. 調べた結果を、確信のあるものと推測のものに分けて一覧で示す。推測したものと、分からなかったもの（例: 本番環境の扱い、禁止したい操作）は、ユーザーに質問して確定させる。
3. `templates/CLAUDE.md` の見出しと順番を変えずに、確定した内容で CLAUDE.md を書く。
   - 見出しは追加・削除しない。書くことがない見出しは「なし」と書く。
   - 一般論（「読みやすいコードを書く」など）は書かない。このリポジトリ固有のことだけを書く。
   - 全体で 100 行以内に収める。
4. `templates/settings.json` を元に `.claude/settings.json` を作る。
   - 実際に使っているコマンドだけを `allow` に残す（例: pnpm を使っていなければ pnpm の行を消す）。
   - `deny` は消さない。リポジトリ固有の禁止事項があれば追加する。
   - 既に `.claude/settings.json` がある場合は、既存の設定を残したまま、足りないキーだけを足す。
5. 既に CLAUDE.md がある場合は、上書きせずに差分を示し、ユーザーの確認を取ってから反映する。
6. 最後に、作成・変更したファイルと、ユーザーが確認すべき点を箇条書きで報告する。
