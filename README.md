macos-wakelog-collector
=======================

## Terraform

### Install
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform jq
```

### Login

```bash
# list profile
aws configure list-profile

aws sso login --profile=XXXXXX

# set profile to default
export AWS_PROFILE=XXXXX

# hello world
aws s3 ls
```

### Create a bucket

```bash
export TFSTATE_BUCKET_NAME="zunda-wlc-tf-state"
aws s3api create-bucket \
  --bucket $TFSTATE_BUCKET_NAME \
  --region ap-northeast-1 \
  --create-bucket-configuration "LocationConstraint=ap-northeast-1"
```

### Edit before deployment

- `terraform/variables.tf`: namespace and client token

### Deploy

```bash
terraform init
terraform plan
terraform apply -auto-approve

# note your invoke url
terraform output -raw upload_ticket_server-invoke_url
```

## Jamf

### edit managed configuration

open `managed_config/info.plist` and edit
- `token`: client token (same as described in `terraform/variables.tf` file)
- `endpoint`: output from terraform

### upload pmlog.sh and upload.sh

(TBD)