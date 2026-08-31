terraform {
  backend "s3" {
    bucket  = "terraform-infrastructure-tstate"
    key     = "aws-infrastructure/terraform.tfstate"
    region  = "ap-south-1"
    encrypt = true
  }
}