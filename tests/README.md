# 設定のテストの仕組み

cosmos のテストは、jest などのテストフレームワークを使わない独自の作りです。テスト対象が bash のスクリプトと、workflow（YAML）に埋め込まれた shell であることと、全リポジトリの CI の元になる cosmos に依存パッケージを増やさないためです。使うのは bash・jq・Node.js の標準機能と、`tools/lint` にある `yaml` パッケージだけです。

このページでは、それぞれのテストが「何を入力して、何と比べて、どうなったら失敗とするか」を説明します。

## 全体の流れ

cosmos に PR を出すと、`.github/workflows/test-config.yml` が次の順で動きます。どれかが失敗したら、その PR はマージしないでください。

```
PR を作る / push する
  │
  ├─ actionlint ............ workflow を静的に検査（数秒）
  ├─ 単体テスト ............ aws-guard.sh の判定表、CI 失敗コメントのスナップショット（数秒）
  └─ e2e-*（7 つ） ......... PR 版の ci.yml をサンプルごとに実行（数分、並列）
        └─ 結合テストの判定 ... 7 つの結果を期待の表と比べる
```

---

## 1. 静的チェック（actionlint）

**何を確かめるか:** workflow の書き間違い。YAML の構文、`${{ }}` の式、`needs` や `steps` の参照、`run:` に書いた shell（shellcheck）を検査します。

**流れ:**
1. `pip install` で、バージョンを固定した actionlint と shellcheck を入れる。
2. `.github/workflows/*.yml` と `sync/.github/workflows/*.yml` を検査する。
3. 指摘が 1 件でもあれば失敗。

**例:** 存在しない `steps.foo.outputs.bar` を参照した、同じステップ内で `$GITHUB_ENV` に書いた値を読もうとした、shell の変数を引用符で囲み忘れた、など。

---

## 2. 単体テスト: aws-guard.sh（`tests/aws-guard/`）

**何を確かめるか:** Claude Code が `aws` コマンドを実行しようとしたときに、hook（`plugins/team-dev/scripts/aws-guard.sh`）が正しく「許可・確認・拒否」を判定するか。

**ファイル:**
| ファイル | 役割 |
| --- | --- |
| `cases.tsv` | 判定表。1 行に「期待する判定 <TAB> コマンド」。`#` で始まる行はコメント |
| `run.sh` | 判定表を 1 行ずつ hook に渡して比べる |

**流れ（1 行ごと）:**
1. コマンドを、Claude Code が hook に渡すのと同じ形の JSON（`{"tool_input": {"command": "..."}}`）にする。
2. `aws-guard.sh` の標準入力に渡して実行する。
3. 出力の `permissionDecision` を読む。出力がなければ `allow`（通常の許可設定に任せる）とみなす。
4. 期待する判定と違えば `NG` と表示し、最後に失敗件数が 1 以上なら失敗。

**判定表の例:**
```
allow	aws s3 ls
ask	aws ec2 terminate-instances --instance-ids i-123
ask	bash -c "aws ec2 terminate-instances --instance-ids i-1"
deny	aws ssm get-parameter --name /app/token --with-decryption
```

**ケースを足すとき:** すり抜けを見つけたら、先にその行を `cases.tsv` に足して `tests/aws-guard/run.sh` が失敗することを確かめ、それから `aws-guard.sh` を直して成功させます。

---

## 3. 単体テスト: CI 失敗コメント（`tests/ci-report/`）

**何を確かめるか:** CI が失敗したときに PR に載せるコメントの文面。`ci.yml` の各ジョブにある「失敗の内容をまとめる」ステップが、決まったログから決まった Markdown を作るか（スナップショットテスト）。

**ファイル:**
```
tests/ci-report/
├─ run.mjs                     テストの実行役
└─ cases/<ケース名>/
   ├─ case.json                対象のジョブ名、ステップに渡す環境変数（どのチェックが失敗したか）
   ├─ logs/                    チェックの出力（tsc.log、php-test.log など）の見本
   ├─ workspace/               （必要なときだけ）gitleaks の results.sarif など
   └─ expected.md              期待するコメントの文面
```

**流れ（ケースごと）:**
1. `run.mjs` が `.github/workflows/ci.yml` を読み、`case.json` の `job` にある「失敗の内容をまとめる」ステップの `run:` を**そのまま**取り出す。テスト用の写しは作らないので、`ci.yml` を直せばテストもその内容を使います。
2. 一時ディレクトリに `logs/` と `workspace/` をコピーする。
3. `case.json` の `env`（例: `TSC=failure`）を環境変数にして、取り出したスクリプトを `bash -eo pipefail` で実行する。
4. できた `report.md` を `expected.md` と 1 文字ずつ比べる。違えば失敗し、実際の出力を表示する。
5. `case.json` に `mustNotContain` があれば、その文字列（秘密情報の値の見本）が出力に含まれていないことも確かめる。

**文面を変えたとき:**
```sh
UPDATE=1 node tests/ci-report/run.mjs   # expected.md を作り直す
git diff tests/ci-report                # 変わった文面を確認して、PR に含める
```
`UPDATE=1` は期待値を上書きするだけなので、差分を人が読んで意図どおりかを判断してください。

---

## 4. 結合テスト（`tests/ci-e2e/`）

**何を確かめるか:** PR 版の `ci.yml` 全体が、実際の GitHub Actions 上で正しく成功・失敗するか。各リポジトリは `ci.yml@main` を使うので、ここで確かめないと、マージしてから初めて問題に気づくことになります。

**サンプル（`tests/ci-e2e/fixtures/`）:**
| サンプル | 中身 | 失敗すべきチェック |
| --- | --- | --- |
| `clean` | 正しい TS・Terraform・PHP・GAS | なし |
| `ts-type-error` | 型エラーのある TS | TypeScript |
| `tf-fmt` | 書式の崩れた `.tf` | Terraform |
| `tracked-env` | コミットされた `.env`（中身はダミー） | 秘密情報 |
| `php-syntax-error` | 構文エラーのある `.php` | PHP |
| `php-script-fail` | `composer test` が失敗する（`>=8.2` なので PHP 8.2 で実行） | PHP |
| `gas-syntax-error` | 構文エラーのある GAS の `.js` | GAS |

**流れ:**
1. `test-config.yml` の `e2e-<サンプル名>` が、`uses: ./.github/workflows/ci.yml` で**この PR の** `ci.yml` を呼ぶ。渡す入力は次の 3 つ。
   - `working-directory`: そのサンプルのディレクトリ。ci.yml はリポジトリ全体ではなく、ここだけを調べる。
   - `comment: false`: PR へのコメントをしない。
   - `allow-failure: true`: チェックが失敗してもジョブは成功扱いにする（わざと壊したサンプルで PR のチェックが赤くならないように）。結果は `outputs` で返す。
2. ci.yml の各ジョブが、最後に自分の結果（`success` / `failure`）を `outputs` に書く。
3. `結合テストの判定` が、7 サンプル × 5 チェックの結果を 1 つの表にし、`EXPECTED` の表と比べる。1 か所でも違えば失敗し、期待と実際の表をログに出す。

**ログでの確かめ方:** 失敗したら、Actions の `結合テストの判定` のログで「期待」と「実際」の表を見比べ、違う行のサンプルの `e2e-<サンプル名>` のログを開きます。

**サンプルを足すとき:**
1. `tests/ci-e2e/fixtures/<名前>/` に、確かめたい状態のファイルを置く（秘密情報はダミーの値にする）。
2. `test-config.yml` に `e2e-<名前>` のジョブを足し、`verify` の `needs`・`RESULTS`・`EXPECTED` に 1 行ずつ足す。

---

## 手元で実行する

```sh
npm ci --prefix tools/lint                       # yaml パッケージ（ci-report が使う）
tests/aws-guard/run.sh                           # aws-guard の判定表
node tests/ci-report/run.mjs                     # CI 失敗コメントのスナップショット
pip install actionlint-py shellcheck-py
actionlint .github/workflows/*.yml sync/.github/workflows/*.yml
```

結合テストは GitHub Actions 上でしか動きません。PR を作るか、Actions タブから `test-config` を手動で実行してください。

## テストの対象外

`@claude review` / `@claude fix` は AI の出力が毎回変わるため、自動テストの対象外です。問題を仕込んだ PR でレビューさせ、指摘できたかを人が確認してください。
