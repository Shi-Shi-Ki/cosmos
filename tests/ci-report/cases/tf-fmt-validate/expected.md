### ❌ Terraform fmt

次のファイルの書式が揃っていません。`cd terraform && terraform fmt -recursive` を実行し、結果をコミットしてください。

```
ssm.tf
main.tf
```

### ❌ Terraform validate

構文・参照・型の誤りがあります。抜粋の `Error:` と `on <ファイル> line <行>` の箇所を直してください。手元では `cd terraform && terraform init -backend=false && terraform validate` で確認できます。

<details><summary>エラーの抜粋</summary>

```
Error: Reference to undeclared input variable

  on ssm.tf line 4, in resource "aws_ssm_parameter" "slack_token":
   4:   value = var.slack_tokn

An input variable with the name "slack_tokn" has not been declared.
```
</details>

