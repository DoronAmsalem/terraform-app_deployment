terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

provider "aws" {
  region = var.aws_region["region"]
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}
