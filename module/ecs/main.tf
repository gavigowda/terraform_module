terraform {
  ### This module is now only being tested with Terraform 1.0.x. However, to make upgrading easier, we are setting
  ## 0.13.0 as the minimum version, as that version has support for module depends_on, which we need for the ECS cluster.
  required_version = ">= 1.0.0"

#we have to use aws version 3.0
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.44.0"
    }
  }
}

resource "aws_ecs_cluster" "ecs" {
  count              = var.create_resources ? 1 : 0
  name               = var.cluster_name
 #capacity_providers = aws_ecs_capacity_provider.capacity_provider[*].name
  tags               = var.custom_tags_ecs_cluster

  # dynamic "default_capacity_provider_strategy" {
  #   for_each = aws_ecs_capacity_provider.capacity_provider
  #   content {
  #     capacity_provider = default_capacity_provider_strategy.value.name
  #     weight            = 1
  #   }
  # }

  dynamic "setting" {
    # The content of the for_each attribute does not matter, as it is only used to indicate if this block should be
    # enabled or not.
    for_each = var.enable_cluster_container_insights ? ["enabled"] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }
}
resource "aws_launch_template" "ecs" {
  count = var.create_resources ? 1 : 0


  name_prefix   = "${var.cluster_name}-"  # need to get clarity on this while creating
  image_id      = var.cluster_instance_ami
  instance_type = var.cluster_instance_type
  key_name      = var.cluster_instance_keypair_name
  user_data     = local.user_data
  ebs_optimized = var.cluster_instance_ebs_optimized
  
  iam_instance_profile {
  name = var.iam_instance_profile
    
   }

   network_interfaces {
    associate_public_ip_address = var.cluster_instance_associate_public_ip_address
    security_groups             = var.security_groups
  }

  monitoring {
    enabled = var.cluster_detailed_monitoring
  }

  block_device_mappings {
    device_name = var.cluster_instance_block_device_name
    ebs {
      volume_size           = var.cluster_instance_root_volume_size
      volume_type           = var.cluster_instance_root_volume_type
      encrypted             = var.cluster_instance_root_volume_encrypted
      delete_on_termination = var.cluster_instance_ebs_delete_on_termination
      iops                  = var.cluster_instance_ebs_iops
      kms_key_id            = var.cluster_instance_ebs_kms_key_id
      snapshot_id           = var.cluster_instance_ebs_snapshot_id
      throughput            = var.cluster_instance_ebs_throughput
    }
  }
}
resource "aws_autoscaling_group" "ecs" {
 count = local.auto_scaling_group_count
 

  name                  = local.auto_scaling_group_count == 1 ? var.cluster_name : "${var.cluster_name}-${count.index}"
 
  min_size              = var.cluster_min_size
  max_size              = var.cluster_max_size
  launch_template {
    id      = aws_launch_template.ecs[0].id
    version = aws_launch_template.ecs[0].latest_version
  }
  vpc_zone_identifier   = local.auto_scaling_group_count == 1 ? var.vpc_subnet_ids : [var.vpc_subnet_ids[count.index]]
  
  termination_policies  = var.termination_policies
  protect_from_scale_in = var.autoscaling_termination_protection
  enabled_metrics       = var.cluster_asg_metrics_enabled

  dynamic "tag" {
    for_each = concat(local.default_tags, var.custom_tags_ec2_instances)
    content {
      key                 = tag.value.key
      value               = tag.value.value
      propagate_at_launch = tag.value.propagate_at_launch
    }
  }
}
  resource "aws_ecs_capacity_provider" "capacity_provider" {
  count = local.capacity_provider_count
  name  = local.capacity_provider_count == 1 ? "capa-${var.cluster_name}" : "capa-${var.cluster_name}-${count.index}"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs[count.index].arn
    managed_termination_protection = var.autoscaling_termination_protection ? "ENABLED" : "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = var.capacity_provider_max_scale_step
      minimum_scaling_step_size = var.capacity_provider_min_scale_step
      status                    = "ENABLED"
      target_capacity           = var.capacity_provider_target
    }
  }
}


# #   resource "aws_ecs_cluster_capacity_providers" "this" {
# #   count = (
# #     var.create_resources && local.capacity_provider_count > 0
# #     ? 1
# #     : 0
# #   )

# #   cluster_name = aws_ecs_cluster.ecs[0].name

# #   capacity_providers = aws_ecs_capacity_provider.capacity_provider[*].name

# #   dynamic "default_capacity_provider_strategy" {
# #     for_each = aws_ecs_capacity_provider.capacity_provider
# #     iterator = capacity_provider

# #     content {
# #       capacity_provider = capacity_provider.value.name
# #       weight            = 1
# #     }
# #   }
# # }
# #   }
  locals {

    user_data = (
    var.cluster_instance_user_data_base64 == null
    ? (
      var.cluster_instance_user_data == null
      ? null
      : base64encode(var.cluster_instance_user_data)
    )
    : var.cluster_instance_user_data_base64
  )

   capacity_provider_count  = var.create_resources && var.capacity_provider_enabled ? (var.multi_az_capacity_provider ? length(var.vpc_subnet_ids) : 1) : 0
  auto_scaling_group_count = var.create_resources ? (var.capacity_provider_enabled && var.multi_az_capacity_provider ? length(var.vpc_subnet_ids) : 1) : 0

  

  default_tags = concat([
    {
      key                 = "Name"
      value               = var.cluster_name
      propagate_at_launch = true
    },
    ],
  
     local.capacity_provider_count > 0
    ? [
      {
        key                 = "AmazonECSManaged"
        value               = ""
        propagate_at_launch = true
      }
    ]
    : []
  )
}
