terraform {
required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.44"
    }
  }
}


# ------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region
}

module "security_group" {
  source = "git::https://github.com/tandfgroup/sampledevops.git//modules/security_group1"
}
    
    
    
