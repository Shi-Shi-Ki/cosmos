// 中央で管理する md と plugin の形式チェック。リポジトリのルートで実行する。
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import picomatch from "picomatch";
import { parse } from "yaml";

const RULES_DIR = "sync/.claude/rules";
const REVIEW_MD = "sync/REVIEW.md";
const MANAGED_MARK = "Shi-Shi-Ki/cosmos で管理";
const MAX_RULE_LINES = 40;
const MAX_REVIEW_LINES = 150;
const STALE_DAYS = 180;
const JSON_FILES = [
  ".claude-plugin/marketplace.json",
  "plugins/team-dev/.claude-plugin/plugin.json",
  "plugins/team-dev/hooks/hooks.json",
  "plugins/team-dev/skills/team-init/templates/settings.json",
  "sync-targets.json",
];
const SCRIPTS_DIR = "plugins/team-dev/scripts";

const errors = [];
const warnings = [];
const lineCount = (text) => text.trimEnd().split("\n").length;

// ルール: frontmatter（owner / last-reviewed / paths）、行数、管理対象の目印
for (const file of readdirSync(RULES_DIR).filter((f) => f.endsWith(".md"))) {
  const text = readFileSync(`${RULES_DIR}/${file}`, "utf8");
  const fm = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  if (!fm) {
    errors.push(`${file}: frontmatter がありません`);
    continue;
  }
  const meta = parse(fm[1]) ?? {};
  if (!meta.owner) errors.push(`${file}: owner がありません`);
  if (!meta["last-reviewed"]) {
    errors.push(`${file}: last-reviewed がありません`);
  } else if (Number.isNaN(new Date(meta["last-reviewed"]).getTime())) {
    errors.push(`${file}: last-reviewed が日付ではありません`);
  } else if ((Date.now() - new Date(meta["last-reviewed"])) / 86_400_000 > STALE_DAYS) {
    warnings.push(`${file}: ${STALE_DAYS} 日以上見直されていません`);
  }
  for (const p of [].concat(meta.paths ?? [])) {
    try {
      picomatch(p);
    } catch {
      errors.push(`${file}: paths の "${p}" が不正です`);
    }
  }
  if (!file.startsWith("team-")) errors.push(`${file}: 中央のルールは team- で始めてください`);
  if (!text.includes(MANAGED_MARK)) errors.push(`${file}: 管理対象の目印コメントがありません`);
  if (lineCount(text) > MAX_RULE_LINES) errors.push(`${file}: ${MAX_RULE_LINES} 行を超えています`);
}

// REVIEW.md: 行数と管理対象の目印
const review = readFileSync(REVIEW_MD, "utf8");
if (!review.includes(MANAGED_MARK)) errors.push("REVIEW.md: 管理対象の目印コメントがありません");
if (lineCount(review) > MAX_REVIEW_LINES) errors.push(`REVIEW.md: ${MAX_REVIEW_LINES} 行を超えています`);

// plugin と設定の JSON が壊れていないか
for (const file of JSON_FILES) {
  if (!existsSync(file)) {
    errors.push(`${file}: ありません`);
    continue;
  }
  try {
    JSON.parse(readFileSync(file, "utf8"));
  } catch (e) {
    errors.push(`${file}: JSON として読めません（${e.message}）`);
  }
}

// hooks から呼ぶスクリプトに実行権限があるか
for (const file of readdirSync(SCRIPTS_DIR)) {
  if (!(statSync(`${SCRIPTS_DIR}/${file}`).mode & 0o111)) {
    errors.push(`${SCRIPTS_DIR}/${file}: 実行権限がありません`);
  }
}

warnings.forEach((w) => console.log(`::warning::${w}`));
errors.forEach((e) => console.log(`::error::${e}`));
console.log(`errors: ${errors.length}, warnings: ${warnings.length}`);
process.exit(errors.length ? 1 : 0);
