### ❌ 秘密情報らしき文字列（gitleaks）

| ルール | ファイル:行 | コミット |
| --- | --- | --- |
| slack-bot-token | `src/config.ts:12` | 033697b |
| generic-api-key | `README.md:5` | 033697b |

- **本物の秘密情報の場合:** すぐにその値を無効化して作り直してください。ファイルから消しても、過去のコミットに残ります。
- **誤検知の場合**（サンプル値・テンプレートのダミーなど）: その行を消すか、Actions の Summary にある Fingerprint をリポジトリ直下の `.gitleaksignore` に 1 行で追加してください。

