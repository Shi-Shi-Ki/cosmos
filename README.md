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
│  ├─ .claude/rules/team-*.md           general / ts / gas / terraform / deps
│  └─ .github/workflows/team-*.yml      下の共通 workflow を呼ぶだけの短いファイル
├─ sync-targets.json                    同期先のリポジトリ一覧
├─ tools/lint/                          sync/ と plugin の形式チェック
└─ .github/
   ├─ CODEOWNERS
   └─ workflows/
      ├─ sync.yml                       sync/ を各リポジトリへ PR
      ├─ lint-standards.yml             PR・main で形式チェック
      ├─ refresh-standards.yml          毎月 1 日に内容を見直し、修正 PR を作る
      ├─ claude-review.yml              共通: @claude review（日本語でコメントのみ）
      ├─ claude-fix.yml                 共通: @claude fix（修正 PR を作る）
      └─ ci.yml                         共通: 型・lint・format・テスト・Terraform・秘密情報
```

フェーズ 2 以降（AI レビューのワークフロー、Slack 通知、ルール適用チェック、見逃しからのルール提案、MCP、指摘の月次集計、回帰テスト、最新動向の取り込み）は、設計ドキュメントの「実装の順番」に従って追加します。

## 初回セットアップ（このリポジトリ側で 1 回）

1. **GitHub App を作る**（個人アカウントの Settings → Developer settings → GitHub Apps）
   - Repository permissions: Contents = Read and write、Pull requests = Read and write、Issues = Read and write、Workflows = Read and write（`sync/.github/workflows` を配るため）
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

1. 同期 PR（`chore: 共通 Claude 設定の同期`）をマージする。REVIEW.md、`.claude/rules/team-*.md`、`.github/workflows/team-*.yml` が入ります。
   - workflow を動かすには、そのリポジトリの Secrets に `CLAUDE_CODE_OAUTH_TOKEN` を登録し、https://github.com/apps/claude をインストールする。
   - `@claude fix` を使うには、Settings → Actions → General で「Allow GitHub Actions to create and approve pull requests」を有効にする。
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

## 共通 workflow（@claude review / @claude fix / CI）

処理の本体は cosmos の `.github/workflows/{claude-review,claude-fix,ci}.yml`（reusable workflow）にあり、各リポジトリには呼び出すだけの `team-*.yml` が同期されます。本体を直してマージすれば、全リポジトリに次の実行から反映されます（`@main` を参照しているため）。

| PR へのコメント | 動き |
| --- | --- |
| `@claude review` | 全体をレビューし、日本語でコメントする。コードは変更しない |
| `@claude review terraform/ だけ` | 後ろの文で範囲・観点を絞る |
| `@claude fix [追加の指示]` | 指摘を直した修正 PR を、元の PR のブランチに向けて作る |

- 反応するのは、リポジトリのオーナー・メンバー・共同編集者のコメントだけです。
- 本体の変更は全リポジトリに即座に効くので、PR で慎重にレビューしてください。
- `sync/` の中では、このリポジトリを `{{COSMOS_REPO}}` と書きます。同期のときに、このリポジトリ名（owner/repo）に置き換わります。

## 業務用に複製して使うとき

cosmos を会社の Organization に複製（private 推奨）すると、同期されるファイルは自動でその複製を参照します。個人の cosmos には依存しません。複製先では次を行います。

1. Settings → Secrets and variables → Actions に、上の「初回セットアップ」と同じ Variables / Secrets を登録する。`CLAUDE_CODE_OAUTH_TOKEN` は Team アカウントで発行する。
2. Team の Code Review（`@claude review`）を使う場合は、Variables に `SYNC_CLAUDE_REVIEW` = `false` を登録する。`team-claude-review.yml` が配られなくなり、同じ言葉で二重に動くのを防げます（既に配ったものは、次の同期で削除されます）。
3. Settings → Actions → General → Access で、同じ Organization のリポジトリからの利用を許可する（private の reusable workflow を呼ぶため）。
4. 次の 4 か所を書き換える。1 つ目は、書き換えるまで lint が警告します。
   - `plugins/team-dev/skills/team-init/templates/settings.json` の marketplace の `repo`
   - `.claude-plugin/marketplace.json` の `owner`
   - `.github/CODEOWNERS`
   - `sync/.claude/rules/team-*.md` の `owner`

## 注意

- 各リポジトリの REVIEW.md、`.claude/rules/team-*.md`、`.github/workflows/team-*.yml` は同期で上書きされます。直接編集しないでください。
- Code Review は PR のベースブランチにある REVIEW.md を読みます。同期 PR をマージするまで、新しい基準は効きません。
- `aws-guard.sh` は、Claude が実行する aws コマンドを調べ、参照系（describe / list / get など）以外なら実行前に承認を求めます。`--with-decryption` は拒否します。`bash -c "..."` や `--profile` 付きの書き方も判定しますが、すべての書き方を防げるわけではありません。確実に止めたい操作は IAM の権限で止めてください。
- `format.sh` は、各リポジトリに prettier / eslint（`node_modules/.bin`）、`terraform`、`shfmt` があるときだけ整形します。ないツールは飛ばします。
