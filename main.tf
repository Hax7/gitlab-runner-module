resource "aws_iam_policy" "gitlab-runner-manager-policy" {
  count  = var.enabled && var.create_manager ? 1 : 0
  name   = "docker-autoscaler"
  policy = jsonencode(local.manager_policy)
}

resource "aws_iam_role" "gitlab-runner-manager-role" {
  count = var.enabled && var.create_manager ? 1 : 0
  name  = "gitlab-runner-manager-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = [aws_iam_policy.gitlab-runner-manager-policy[0].arn, "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

}

resource "aws_iam_instance_profile" "gitlab-runner-manager-profile" {
  count = var.enabled && var.create_manager ? 1 : 0
  name  = "gitlab-runner-profile"
  role  = aws_iam_role.gitlab-runner-manager-role[0].name
}

resource "aws_launch_template" "gitlab-runner" {
  count                  = var.enabled ? 1 : 0
  image_id               = local.asg-runners-ami
  instance_type          = var.asg_runners_ec2_type
  vpc_security_group_ids = var.asg_security_groups
  instance_market_options {
    market_type = "spot"
  }

  dynamic "iam_instance_profile" {
    for_each = var.asg_iam_instance_profile != null ? var.asg_iam_instance_profile[*] : []
    content {
      arn = iam_instance_profile.value
    }
  }

  dynamic "tag_specifications" {
    for_each = lenght(var.tags) > 0 ? [1] : []
    content {
      resource_type = "instance"
      tags          = var.tags
  }

}

resource "aws_autoscaling_group" "gitlab-runners" {
  count                 = var.enabled ? 1 : 0
  max_size              = var.asg_max_size
  min_size              = 0
  desired_capacity      = 0
  vpc_zone_identifier   = var.asg_subnets
  suspended_processes   = ["AZRebalance"]
  protect_from_scale_in = true
  launch_template {
    id      = aws_launch_template.gitlab-runner[0].id
    version = "$Latest"
  }
  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_instance" "gitlab_runner" {
  count                  = var.enabled && var.create_manager && var.auth_token != null ? 1 : 0
  ami                    = data.aws_ami.latest_amazon_linux_2023.image_id
  instance_type          = var.manager_ec2_type
  iam_instance_profile   = aws_iam_instance_profile.gitlab-runner-manager-profile[0].name
  subnet_id              = var.asg_subnets[0]
  vpc_security_group_ids = var.manager_security_groups
  # vpc_security_group_ids = [aws_security_group.allow_ssh_docker.id]
  tags = {
    Name = "Gitlab runner autoscaling manager"
  }
  user_data_replace_on_change = true
  # User data script to install Docker and GitLab Runner
  user_data = templatefile("${path.module}/user-data/manager-user-data.sh.tftpl",
    {
      enable_s3_cache        = var.enable_s3_cache
      s3_bucket_name         = var.enable_s3_cache ? aws_s3_bucket.s3_cache[0].id : null
      aws_region             = data.aws_region.current.name
      autoscaling_group_name = aws_autoscaling_group.gitlab-runners[0].name
      auth_token             = var.auth_token
      concurrent_limit       = local.concurrent-limit
      max_instances          = var.asg_max_size
      capacity_per_instance  = var.capacity_per_instance

  })
  lifecycle {
    ignore_changes = [
      ami,
    ]
  }
}

resource "aws_s3_bucket" "s3_cache" {
  count  = var.enabled && var.enable_s3_cache ? 1 : 0
  bucket = "gitlab-shared-cache-${random_id.this.hex}"
  tags = {
    Service = "Gitlab runner s3 shared cache"
  }
}

resource "random_id" "this" {
  byte_length = 8
}
