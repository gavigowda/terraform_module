# CREATE AN APPLICATION LOAD BALANCER (ALB)
# This template creates an ALB, the necessary security groups, and sets up the desired ALB Listeners. A single ALB is
# expected to serve as the load balancer for potentially multiple ECS Services and Auto Scaling Groups.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  # This module is now only being tested with Terraform 1.0.x. However, we are setting 0.13.0 as the minimum version
  # as that version added support for Terraform native variable validation. See:
  # https://www.terraform.io/docs/language/values/variables.html#custom-validation-rules
  required_version = ">= 1.0.0"
}

# ---------------------------------------------------------------------------------------------------------------------
# SET MODULE DEPENDENCY RESOURCE
# This works around a terraform limitation where we can not specify module dependencies natively.
# See https://github.com/hashicorp/terraform/issues/1178 for more discussion.
# By resolving and computing the dependencies list, we are able to make all the resources in this module depend on the
# resources backing the values in the dependencies list.
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "dependency_getter" {
  triggers = {
    instance = join(",", var.dependencies)
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN APPLICATION LOAD BALANCER
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_alb" "alb" {
  name     = var.alb_name
  internal = var.is_internal_alb
  subnets  = var.vpc_subnet_ids
#  security_groups = concat(
#    [aws_security_group.alb.id],
#    var.additional_security_group_ids,
#  )

  idle_timeout               = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = var.drop_invalid_header_fields

  tags = var.custom_tags

  dynamic "access_logs" {
    # The contents of the list is irrelevant. The only important thing is whether or not to create this block.
    for_each = var.enable_alb_access_logs ? ["use_access_logs"] : []
    content {
      bucket  = var.alb_access_logs_s3_bucket_name
      prefix  = var.alb_name
      enabled = true
    }
  }

  depends_on = [null_resource.dependency_getter]
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE THE ALB TARGET GROUP & LISTENER RULE
# - To understand the ALB concepts of a Listener, Listener Rule, and Target Group, visit https://goo.gl/jGPQPE.
# - Because many ECS Services may potentially share a single Listener, we must define a Listener at the ALB Level, not
#   at the ECS Service level. We create one ALB Listener for each given port.
# ---------------------------------------------------------------------------------------------------------------------

# Create one HTTP Listener for each given HTTP port.
resource "aws_alb_listener" "http" {
  count = length(var.http_listener_ports)

  load_balancer_arn = aws_alb.alb.arn
  port              = element(var.http_listener_ports, count.index)
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = var.default_action_content_type
      message_body = var.default_action_body
      status_code  = var.default_action_status_code
    }
  }

  depends_on = [null_resource.dependency_getter]
}

# Create one HTTPS Listener for each given HTTPS port and TLS cert ARN passed in by the user. Note that the user may
# also pass in TLS certs issued by ACM, which are handled in the listener below.
resource "aws_alb_listener" "https_non_acm_certs" {
  count = var.https_listener_ports_and_ssl_certs_num

  load_balancer_arn = aws_alb.alb.arn
  port              = var.https_listener_ports_and_ssl_certs[count.index]["port"]
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.https_listener_ports_and_ssl_certs[count.index]["tls_arn"]

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = var.default_action_content_type
      message_body = var.default_action_body
      status_code  = var.default_action_status_code
    }
  }

  depends_on = [null_resource.dependency_getter]
}
