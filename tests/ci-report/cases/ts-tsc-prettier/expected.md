### ❌ 型チェック（tsc）

抜粋の `ファイル(行,列): error TSxxxx` の箇所を直してください。手元では `pnpm exec tsc --noEmit` で確認できます。`Cannot find module` は import のパスか、依存の入れ忘れが原因のことが多いです。

<details><summary>エラーの抜粋</summary>

```
src/app.controller.spec.ts(2,31): error TS2307: Cannot find module '../tmp-nest/src/app.controller' or its corresponding type declarations.
src/app.controller.spec.ts(3,28): error TS2307: Cannot find module '../tmp-nest/src/app.service' or its corresponding type declarations.
```
</details>

### ❌ Format（Prettier）

手元で `pnpm exec prettier --write "**/*.{ts,tsx,js,jsx,mjs,cjs}"` を実行し、結果をコミットしてください。

<details><summary>エラーの抜粋</summary>

```
[warn] src/main.ts
[warn] Code style issues found in the above file. Run Prettier with --write to fix.
```
</details>

