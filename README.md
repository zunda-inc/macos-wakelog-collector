macos-wakelog-collector
=======================

## Prerequisites

Install [Terraform](https://www.terraform.io/) and [AWS CLI (v2)](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

The following commands are available if [Homebrew](https://brew.sh/) is installed.
If you use a package installer, please refer to the official documentation.

```bash
# Terraform
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# AWSCLI V2
brew install awscli
```
Ensure aws command to be executed by AWSAdministratorAccess privileges.

## Checkout

Check out this repository.

## Edit here

### terraform/backend.tf

The `bucket` attribute points to the bucket where Terraform state files are stored.

This bucket is not automatically created by Terraform, so please create it using the AWS Web Console or the aws command as shown below.

```bash
# Bucket name for save the state
export TFSTATE_BUCKET_NAME="XXXXX"

aws s3api create-bucket \
  --bucket $TFSTATE_BUCKET_NAME \
  --region ap-northeast-1 \
  --create-bucket-configuration "LocationConstraint=ap-northeast-1"
```

You can use an existing bucket, but make sure that the `key` is unique.

### terraform/variables.tf

The `default =` in `namespace` is the character that precedes the name of the resource, such as S3 bucket. Be sure to change it.

Change the `default =` in `client_token` to an appropriate string for security purposes. This value will be distributed to client PCs later using MDM such as Jamf Pro.

Tip: You can get a secure random string with the following command

```
ruby -e "range = [*'0'..'9',*'A'..'Z',*'a'..'z']; puts Array.new(64){ range.sample }.join"
```

`aws_region` can be changed as needed.

## Running Terraform

Use the following command to build an environment on AWS using Terraform.

```bash
cd terraform

# Initialization (first time only)
terraform init

# Confirmation of changes
terraform plan

# Application of changes
terraform apply -auto-approve

# Obtain the Invoke URL (to be used later)
terraform output -raw upload_ticket_server-invoke_url
```

## MDM

### Update the configuration file

Edit the following items in the `managed_config/info.plist` file

- `token`: Put the default value set in `client_token` in `terraform/variables.tf`.
- `endpoint`: Put the value of `upload_ticket_server-invoke_url` obtained when running Terraform

### Distribution of settings

Distribute the contents of the above plist in Jamf configuration profiles, etc.

### Run test

Execute the following command on the terminal to which the above settings have been distributed

```bash
# When executed, display.log and power.log are created in `/var/log/wakelog_collector/`
sudo client_scripts/pmlog.sh

# When executed, these log files are uploaded
sudo client_scripts/upload.sh
```

When working properly, buckets ending in `aggregated-logs` will create logs organized by machine name and year, and buckets ending in `archived-logs` will store archives of uploaded files.

# Licenses

```
Copyright 2022 ZUNDA Inc.

Use of this source code is governed by an MIT-style
license that can be found in the LICENSE file or at
https://opensource.org/licenses/MIT.
```

If you need assistance, please contact [ZUNDA Inc.](https://www.zunda.co.jp/)
