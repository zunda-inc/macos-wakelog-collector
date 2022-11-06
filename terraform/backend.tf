# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

terraform {
  backend "s3" {
    bucket  = "zunda-wlc-tf-state"
    region  = "ap-northeast-1"
    key     = "macos-wakelog-collector.tfstate"
    encrypt = false
  }
}