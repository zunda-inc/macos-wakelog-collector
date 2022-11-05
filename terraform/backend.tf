terraform {
  backend "s3" {
    bucket  = "zunda-wlc-tf-state"
    region  = "ap-northeast-1"
    key     = "macos-wakelog-collector.tfstate"
    encrypt = false
  }
}