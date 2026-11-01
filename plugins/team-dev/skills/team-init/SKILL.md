---
name: team-init
description: リポジトリにチーム標準の CLAUDE.md と .claude/settings.json を作成・更新する。新しいリポジトリの導入時や、バージョン情報を更新したいときに使う。
disable-model-invocation: true
---

# team-init

このリポジトリ固有の CLAUDE.md と `.claude/settings.json` を、チームで決めた形で作ります。
共通の規約（`.claude/rules/team-*.md`）と REVIEW.md は中央リポジトリから同期されるので、ここでは書きません。

## 変更してよいファイル

- 作成・変更してよいのは `CLAUDE.md`、`.claude/settings.json`、`.claude/rules/local-*.md` の 3 種類だけ。
- 既存の skills（`.claude/skills/`）、agents、hooks、ソースコードなど、それ以外のファイルは変更しない。既存の skill と内容が重複・矛盾していると気づいた場合は、変更せずに最後の報告で指摘する。

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
   - テンプレートの例のうち、このリポジトリに当てはまらないもの（例: GAS を使っていないのに `clasp deploy` の禁止）は消す。
   - 全体で 100 行以内に収める。
4. 既存の CLAUDE.md に、テンプレートの見出しに当てはまらない規約（言語、命名、コメントの書き方など）があれば、`.claude/rules/local-conventions.md` に移す。
   - チーム共通の規約（`team-*.md`）と同じ内容、一般論、CLAUDE.md と重複する内容（例: 「バージョンは package.json を参照する」）は移さずに消す。
   - 既に `local-*.md` がある場合も、同じ基準で見直して差分を提案する。
   - `team-*.md` がまだ同期されていない場合は、「セキュリティ上の懸念を指摘する」「秘密情報を書かない」のような全リポジトリ共通の内容も、共通ルールで扱うものとして移さない。
5. `templates/settings.json` を元に `.claude/settings.json` を作る。
   - `allow` は、実際に使っているコマンドだけを残す（例: pnpm を使っていれば npm の行は消す、tflint を使っていなければ消す）。
   - `deny` のテンプレートの行は消さない。
   - CLAUDE.md の「禁止事項」のうち、コマンドやファイルで表せるものは `deny` にも追加する（例: `Read(./terraform/*.tfstate*)`、`Bash(docker compose down -v:*)`）。CLAUDE.md の記述はお願いにすぎず、`deny` に書いたものだけが確実に止まるため。
   - 既に `.claude/settings.json` がある場合も、既存の行をそのまま残さず、上の基準で見直す（使っていないコマンドの `allow` を消す、禁止事項を `deny` に足す）。ユーザーが自分で足した行は消さない。判断がつかない行は残して報告する。
   - `.env.example` のようなサンプルファイルは読めるようにしておく（`Read(./.env.*)` のような広いパターンで塞がない）。
6. 既存のファイルを変更する場合は、上書きせずに差分を示し、ユーザーの確認を取ってから反映する。
7. 最後に、作成・変更したファイルと、ユーザーが確認すべき点を箇条書きで報告する。チーム共通の REVIEW.md と `.claude/rules/team-*.md` がまだない場合は、中央リポジトリの `sync-targets.json` への登録が必要であることも伝える。
