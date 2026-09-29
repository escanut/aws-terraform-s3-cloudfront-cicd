#used ~> instead of >= to protect against infra breaking updates 
#for both terraform and aws
terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 6.28"
    }
  }

  backend "s3" {
    bucket = "YOUR-IDENTIFIER-tf-state-tf-state"
    key = "s3-website/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "tf-state-lock"
    encrypt = true
  }

}

provider "aws" {
  region = var.aws_region
}
