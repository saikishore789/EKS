terraform {
  backend "s3" {
    bucket = "eks-terraform-sai"
    key = "eks/terraform.tfstate"
    region = "ap-south-1"
  }
}