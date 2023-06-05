terraform {
  # This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  # 0.13.0 as the minimum version, as that version has support for module depends_on, which we need for the ECS cluster.
  #  required_version = ">= 0.12.26"
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.44"
    }
  }
}

# -------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# -------------------------------------------------------------------------------

provider "aws" {
  region = "us-east-1"
}


module "aws_ecs_cluster" {
 # source = "git::https://github.com/tandfgroup/sampledevops.git//modules/ecs"
  source = "./module/ecs"

}
  
