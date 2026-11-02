// ci.yml の「失敗の内容をまとめる」ステップのスナップショットテスト。
// cases/<名前>/ に入力（case.json・logs/・workspace/）と期待する出力（expected.md）を置く。
// ci.yml からステップのスクリプトをそのまま取り出して実行するので、ci.yml を直せばテストもそれを使う。
// 期待値を作り直すとき: UPDATE=1 node tests/ci-report/run.mjs
import { execFileSync } from "node:child_process";
import { cpSync, existsSync, mkdtempSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "../..");
const require = createRequire(join(root, "tools/lint/package.json"));
const YAML = require("yaml");

const workflow = YAML.parse(readFileSync(join(root, ".github/workflows/ci.yml"), "utf8"));
const update = process.env.UPDATE === "1";
let failed = 0;

for (const name of readdirSync(join(here, "cases")).sort()) {
  const dir = join(here, "cases", name);
  const spec = JSON.parse(readFileSync(join(dir, "case.json"), "utf8"));
  const step = workflow.jobs[spec.job]?.steps.find((s) => s.name === "失敗の内容をまとめる");
  if (!step) throw new Error(`${name}: ${spec.job} に「失敗の内容をまとめる」がありません`);

  const tmp = mkdtempSync(join(tmpdir(), "ci-report-"));
  const logs = join(tmp, "logs");
  const workspace = join(tmp, "workspace");
  cpSync(join(dir, "logs"), logs, { recursive: true, force: true });
  if (existsSync(join(dir, "workspace"))) cpSync(join(dir, "workspace"), workspace, { recursive: true });
  else cpSync(logs, workspace, { recursive: true, filter: () => false });

  execFileSync("bash", ["-eo", "pipefail", "-c", step.run], {
    cwd: existsSync(workspace) ? workspace : tmp,
    env: { PATH: process.env.PATH, LOGS: logs, ...spec.env },
    stdio: ["ignore", "inherit", "inherit"],
  });

  const reportPath = join(logs, "report.md");
  const actual = existsSync(reportPath) ? readFileSync(reportPath, "utf8") : "";
  const expectedPath = join(dir, "expected.md");

  // 秘密情報の値をコメントに載せないこと
  for (const secret of spec.mustNotContain ?? []) {
    if (actual.includes(secret)) {
      console.log(`NG  ${name}: 出力に載せてはいけない文字列が含まれています`);
      failed++;
    }
  }

  if (update) {
    writeFileSync(expectedPath, actual);
    console.log(`更新 ${name}`);
  } else if (!existsSync(expectedPath) || readFileSync(expectedPath, "utf8") !== actual) {
    console.log(`NG  ${name}: expected.md と一致しません。実際の出力:\n${actual}`);
    failed++;
  } else {
    console.log(`OK  ${name}`);
  }
}

if (failed) {
  console.log(`ci-report: ${failed} 件失敗`);
  process.exit(1);
}
