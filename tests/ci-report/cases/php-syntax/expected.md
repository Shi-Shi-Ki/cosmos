### ❌ PHP の構文（PHP 8.2）

抜粋の `in <ファイル> on line <行>` の箇所に構文エラーがあります。手元では `php -l <ファイル>` で確認できます。バージョンが違う場合は、composer.json の `require.php` を確認してください。 実行環境: PHP 8.2（composer.json の require.php から。実行: Docker の php:8.2-cli）

<details><summary>エラーの抜粋</summary>

```
PHP Parse error:  syntax error, unexpected end of file, expecting "," or ";" in src/Controller.php on line 12
Errors parsing src/Controller.php
```
</details>

