### ❌ 既知の脆弱性（composer audit）

依存パッケージに公表済みの脆弱性があります。抜粋のパッケージを、修正されたバージョンに `composer update <パッケージ>` で上げてください。すぐに上げられない場合は、影響を確認して PR に理由を書いてください。

<details><summary>エラーの抜粋</summary>

```
Found 1 security vulnerability advisory affecting 1 package:
| Severity          | high                                                                             |
| CVE               | CVE-2023-29197                                                                   |
```
</details>

### ❌ リポジトリの test（composer test）（PHP 8.3）

composer.json の `scripts.test` が失敗しました。手元で `composer test` を実行して再現してください。CI では PHP の拡張モジュールが手元と違うことがあります。 実行環境: PHP 8.3（composer.json の require.php から。実行: ランナーの PHP）

<details><summary>エラーの抜粋</summary>

```
There was 1 failure:
Failed asserting that two strings are identical.
FAILURES!
Tests: 2, Assertions: 2, Failures: 1.
Script phpunit handling the test event returned with error code 1
```
</details>

