// GAS は ES モジュールではなくスクリプトとして読み込まれるので、vm.Script で構文だけを確かめる（依存なし）。
// 使い方: node gas-syntax.cjs <ファイル一覧のパス>
const fs = require("node:fs");
const vm = require("node:vm");
const files = fs.readFileSync(process.argv[2], "utf8").split("\n").filter(Boolean);
let bad = 0;
for (const file of files) {
  try {
    new vm.Script(fs.readFileSync(file, "utf8"), { filename: file });
  } catch (e) {
    bad++;
    console.log(`${String(e.stack).split("\n")[0]}\n${e.name}: ${e.message}\n`);
  }
}
console.log(`${files.length} ファイルを確認し、${bad} ファイルに構文エラーがありました`);
process.exit(bad ? 1 : 0);
