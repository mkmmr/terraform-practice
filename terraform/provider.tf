provider "aws" {
    region     = "ap-northeast-1"
}

terraform {
    required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 4.64.0"
        }
    }

    backend "s3" {
        bucket = "terraform-raisetech-s3-for-tfstate"
        key    = "terraform.tfstate"
        region = "ap-northeast-1"
    }
}
