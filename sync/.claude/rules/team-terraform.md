---
paths:
  - "**/*.tf"
  - "**/*.tfvars"
owner: "@Shi-Shi-Ki"
last-reviewed: 2026-10-31
---
<!-- Shi-Shi-Ki/cosmos で管理。このリポジトリでは編集しない -->
# Terraform

- provider のバージョンは required_providers で ~> により固定する
- IAM は最小権限。"*" の Action / Resource を使う場合は理由をコメントで残す
- シークレットは Secrets Manager / Secret Manager を参照し、tfvars に書かない
- リソース名変更は moved ブロックで行い、destroy/create を発生させない
- 全リソースに default_tags / labels（owner, env, service）を付ける
- `terraform apply` は実行しない。変更は plan の結果で説明する
