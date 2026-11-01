# cosmos

Claude review package。チーム共通の Claude Code 設定（plugin）とレビュー基準（REVIEW.md、rules）を、このリポジトリで一元管理して各リポジトリへ配ります。

設計の経緯と全体像: [Claude活用ベストプラクティス](https://claude.ai/artifact/APvKnLz7RYgecWcRBtXBW6)（「実装一覧」の章）

## 構成（フェーズ 1）

```
cosmos/
├─ .claude-plugin/marketplace.json      plugin の配布元
├─ plugins/team-dev/                    各自の Claude Code が読むもの
│  ├─ .claude-plugin/plugin.json
│  ├─ skills/team-init/                 各リポジトリの CLAUDE.md と settings.json を生成
│  ├─ hooks/hooks.json                  編集後の自動整形、aws コマンドの確認
│  └─ scripts/{format.sh,aws-guard.sh}
├─ sync/                                全リポジトリへそのままコピー
│  ├─ REVIEW.md                         Code Review の基準
│  └─ .claude/rules/team-*.md           general / ts / gas / terraform
├─ sync-targets.json                    同期先のリポジトリ一覧
├─ tools/lint/                          sync/ と plugin の形式チェック
└─ .github/
   ├─ CODEOWNERS
   └─ workflows/
      ├─ sync.yml                       sync/ を各リポジトリへ PR
      ├─ lint-standards.yml             PR・main で形式チェック
      └─ refresh-standards.yml          毎月 1 日に内容を見直し、修正 PR を作る
```

フェーズ 2 以降（AI レビューのワークフロー、Slack 通知、ルール適用チェック、見逃しからのルール提案、MCP、指摘の月次集計、回帰テスト、最新動向の取り込み）は、設計ドキュメントの「実装の順番」に従って追加します。

## 初回セットアップ（このリポジトリ側で 1 回）

1. **GitHub App を作る**（個人アカウントの Settings → Developer settings → GitHub Apps）
   - Repository permissions: Contents = Read and write、Pull requests = Read and write
   - 作成後、同期先のリポジトリにインストールする
2. **このリポジトリに Variables / Secrets を登録する**（Settings → Secrets and variables → Actions）
   - Variables: `SYNC_APP_ID`（App ID）
   - Secrets: `SYNC_APP_PRIVATE_KEY`（App の秘密鍵）
   - Secrets: `CLAUDE_CODE_OAUTH_TOKEN`（月次見直し用。Team プランのアカウントでログインした状態で `claude setup-token` を実行して発行する）
   - GitHub App は、同期先に加えてこのリポジトリ自身にもインストールする（月次見直しの PR を作るため）
3. **main を保護する**（Settings → Branches）
   - Require a pull request before merging、Require review from Code Owners
   - Require status checks: `lint`
4. **Claude の管理画面で Code Review を設定する**
   - Review runs: Manual（`@claude review` のときだけ）
   - レビューレベル: Quick、月額の上限を設定
5. **同期先を登録する**: `sync-targets.json` の `repos` にリポジトリ名（オーナーなし）を追加して PR を出す

```json
{
  "repos": ["expense-gas", "backoffice-infra"]
}
```

## 各リポジトリでやること（導入時に 1 回）

1. 同期 PR（`chore: 共通 Claude 設定の同期`）をマージする。REVIEW.md と `.claude/rules/team-*.md` が入ります。
2. Claude Code（CLI または VS Code）で plugin を入れる。先頭の `/` を付けてコマンドとして実行する（付けないと Claude への依頼として扱われる）。

   ```
   /plugin marketplace add Shi-Shi-Ki/cosmos
   /plugin install team-dev@cosmos
   ```

3. 対象リポジトリで `/team-dev:team-init` を実行し、CLAUDE.md と `.claude/settings.json` を生成してコミットする。以降は settings.json に書かれた marketplace から、他のメンバーにも plugin のインストールが促されます。
4. 固有のレビュー観点があれば、サブディレクトリの REVIEW.md（例: `infra/REVIEW.md`）か `.claude/rules/local-*.md` に書く。

## ルールを変更するとき

- `sync/` 配下を編集して PR を出す。`lint` が通り、CODEOWNERS の承認があればマージできます。
- ルールを見直したら、frontmatter の `last-reviewed` を更新する。180 日を超えると警告が出ます。
- 上限: ルール 1 ファイル 40 行、REVIEW.md 150 行。超えたら分割するか削る。
- マージすると `sync.yml` が同期先の全リポジトリへ PR を出します。

## 月次の見直し（refresh-standards.yml）

毎月 1 日 9:00（日本時間）に、Claude が `sync/REVIEW.md` と `team-*.md` を最新の公式情報と照らして見直します。Actions タブの Run workflow から手動でも実行できます。

- 直すべき点があれば、PR（`chore/refresh-standards`）を作ります。本文に、変更点と根拠の URL、人間が判断すべき点が書かれます。CODEOWNERS にレビューが依頼されるので、根拠を確かめてマージしてください。
- `last-reviewed` から 180 日を過ぎたルールは全項目を確認し、問題がなければ日付だけを更新する PR になります。マージした時点で、人間の見直しが済んだ扱いです。
- 直す点がなく、判断が必要な点だけがあれば Issue を、実行が失敗すれば失敗の Issue を作ります。何もなければ何も作りません。
- 実行には `CLAUDE_CODE_OAUTH_TOKEN` を発行した人の Team の利用枠を使います。トークンは発行した人に紐づくので、退職・異動のときは再発行してください。

## 注意

- 各リポジトリの REVIEW.md と `.claude/rules/team-*.md` は同期で上書きされます。直接編集しないでください。
- Code Review は PR のベースブランチにある REVIEW.md を読みます。同期 PR をマージするまで、新しい基準は効きません。
- `aws-guard.sh` は、Claude が実行する aws コマンドを調べ、参照系（describe / list / get など）以外なら実行前に承認を求めます。`--with-decryption` は拒否します。`bash -c "..."` や `--profile` 付きの書き方も判定しますが、すべての書き方を防げるわけではありません。確実に止めたい操作は IAM の権限で止めてください。
- `format.sh` は、各リポジトリに prettier / eslint（`node_modules/.bin`）、`terraform`、`shfmt` があるときだけ整形します。ないツールは飛ばします。
