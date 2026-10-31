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
│  ├─ hooks/hooks.json                  編集後の自動整形
│  └─ scripts/format.sh
├─ sync/                                全リポジトリへそのままコピー
│  ├─ REVIEW.md                         Code Review の基準
│  └─ .claude/rules/team-*.md           general / ts / gas / terraform
├─ sync-targets.json                    同期先のリポジトリ一覧
├─ tools/lint/                          sync/ と plugin の形式チェック
└─ .github/
   ├─ CODEOWNERS
   └─ workflows/
      ├─ sync.yml                       sync/ を各リポジトリへ PR
      └─ lint-standards.yml             PR・main・毎月 1 日に形式チェック
```

フェーズ 2 以降（AI レビューのワークフロー、Slack 通知、ルール適用チェック、見逃しからのルール提案、MCP、指摘の月次集計、回帰テスト、最新動向の取り込み）は、設計ドキュメントの「実装の順番」に従って追加します。

## 初回セットアップ（このリポジトリ側で 1 回）

1. **GitHub App を作る**（個人アカウントの Settings → Developer settings → GitHub Apps）
   - Repository permissions: Contents = Read and write、Pull requests = Read and write
   - 作成後、同期先のリポジトリにインストールする
2. **このリポジトリに Variables / Secrets を登録する**（Settings → Secrets and variables → Actions）
   - Variables: `SYNC_APP_ID`（App ID）
   - Secrets: `SYNC_APP_PRIVATE_KEY`（App の秘密鍵）
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
2. VS Code の Claude Code で plugin を入れる。

   ```
   /plugin marketplace add Shi-Shi-Ki/cosmos
   /plugin install team-dev@cosmos
   ```

3. `/team-init` を実行し、CLAUDE.md と `.claude/settings.json` を生成してコミットする。以降は settings.json に書かれた marketplace から、他のメンバーにも plugin のインストールが促されます。
4. 固有のレビュー観点があれば、サブディレクトリの REVIEW.md（例: `infra/REVIEW.md`）か `.claude/rules/local-*.md` に書く。

## ルールを変更するとき

- `sync/` 配下を編集して PR を出す。`lint` が通り、CODEOWNERS の承認があればマージできます。
- ルールを見直したら、frontmatter の `last-reviewed` を更新する。180 日を超えると警告が出ます。
- 上限: ルール 1 ファイル 40 行、REVIEW.md 150 行。超えたら分割するか削る。
- マージすると `sync.yml` が同期先の全リポジトリへ PR を出します。

## 注意

- 各リポジトリの REVIEW.md と `.claude/rules/team-*.md` は同期で上書きされます。直接編集しないでください。
- Code Review は PR のベースブランチにある REVIEW.md を読みます。同期 PR をマージするまで、新しい基準は効きません。
- `format.sh` は、各リポジトリに prettier / eslint（`node_modules/.bin`）、`terraform`、`shfmt` があるときだけ整形します。ないツールは飛ばします。
