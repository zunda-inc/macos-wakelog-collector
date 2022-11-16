macos-wakelog-collector
=======================

## 前提条件

[Terraform](https://www.terraform.io/) と [AWS CLI (v2)](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) をインストールしてください。

以下のコマンドは [Homebrew](https://brew.sh/) が導入されている場合に利用できます。
パッケージインストーラーなどを利用する場合は、別途公式ドキュメントを参照してください。

```bash
# Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# AWSCLI V2
brew install awscli
```

AWSAdministratorAccess ロールを持つユーザーで aws コマンドが利用できるように設定してください。

## コードのチェックアウト

本レポジトリをチェックアウトしてください。

## ファイルの編集

### terraform/backend.tf

`bucket =` 値は Terraform のステートファイルを保存するバケットを示すようにします。

このバケットは Terraform によって自動的に作成されませんので、AWS の Web Console あるいは以下のように aws コマンドで作成してください。

```bash
# バケット名
export TFSTATE_BUCKET_NAME="XXXXX"

aws s3api create-bucket \
  --bucket $TFSTATE_BUCKET_NAME \
  --region ap-northeast-1 \
  --create-bucket-configuration "LocationConstraint=ap-northeast-1"
```

既存のバケットを利用することも可能ですが、 `key` は被らないようにしてください。

### terraform/variables.tf

namespace の `default =` は S3 バケットなどのリソース名の先頭につく文字です。必ず変更してください。

client_token の `default =` はセキュリティ上、適当な文字列に変更してください。この値は後ほど Jamf Pro などの MDM を利用してクライアントPCに配布します。

ヒント: 以下のコマンドでセキュアなランダム文字列を手に入れることができます。

```
ruby -e "range = [*'0'..'9',*'A'..'Z',*'a'..'z']; puts Array.new(64){ range.sample }.join"
```

aws_region は必要に応じて変更することができます。

## Terraform の実行

下記コマンドで Terraform を利用して AWS に環境を構築します。

```bash
cd terraform

# 初期化 (初回のみ)
terraform init

# 変更点の確認
terraform plan

# 変更の適用
terraform apply -auto-approve

# Invoke URL の確認 (後で使います)
terraform output -raw upload_ticket_server-invoke_url
```

## MDM

### 設定ファイルの更新

`managed_config/info.plist` ファイルの以下の項目を編集します。

- `token`: `terraform/variables.tf` の `client_token` で設定したdefault値を入れます
- `endpoint`: Terraform を実行した際に得られた `upload_ticket_server-invoke_url` の値を入れます

### 設定の配布

上記の plist の内容を Jamf の構成プロファイルなどで配布します。

### 動作試験

上記設定が配布された端末で以下のコマンドを実行します

```bash
# 実行すると `/var/log/wakelog_collector/` に display.log と power.log が作成される
sudo client_scripts/pmlog.sh

# 実行すると、これらのログファイルがアップロードされる
sudo client_scripts/upload.sh
```

正しく動作している場合、 `aggregated-logs` で終わるバケットにマシン名と年月ごとに整理されたログが作成され、`archived-logs` で終わるバケットにアップロードしたファイルのアーカイブが保存されます。

### スクリプトの配布

`client_script/` 以下の 2 つのスクリプトが管理者権限で定期的に実行されるよう、Jamf などの MDM で配布してください。

# ライセンス

```
Copyright 2022 ZUNDA Inc.

Use of this source code is governed by an MIT-style
license that can be found in the LICENSE file or at
https://opensource.org/licenses/MIT.
```

サポートが必要な場合は [ZUNDA株式会社](https://www.zunda.co.jp/) までお問い合わせください。
