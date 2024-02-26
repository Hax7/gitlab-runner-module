resource "aws_iam_policy" "gitlab-runner-manager-policy" {
  count = var.enabled && var.create-manager ? 1 : 0
  name = "docker-autoscaler"
  policy = templatefile("${path.module}/policies/instance-docker-autoscaler-policy.json",
    {
      autoscaling_group_arn = aws_autoscaling_group.gitlab-runners[0].arn
      autoscaling_group_name = aws_autoscaling_group.gitlab-runners[0].name
      aws_region = data.aws_region.current.name
      aws_account_id = data.aws_caller_identity.current.account_id
    })
}

resource "aws_iam_role" "gitlab-runner-manager-role" {
  count = var.enabled && var.create-manager ? 1 : 0
  name = "gitlab-runner-manager-role"
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
  managed_policy_arns =  [aws_iam_policy.gitlab-runner-manager-policy[0].arn, "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

}

resource "aws_iam_instance_profile" "gitlab-runner-manager-profile" {
  count = var.enabled && var.create-manager ? 1 : 0
  name = "gitlab-runner-profile"
  role = aws_iam_role.gitlab-runner-manager-role[0].name
}

resource "aws_launch_template" "gitlab-runner" {
  count = var.enabled ? 1 : 0
  name = "gitlab-runner-template"
  image_id = local.asg-runners-ami
  instance_type = var.asg-runners-ec2-type
  vpc_security_group_ids = var.asg-security-groups
  instance_market_options {
    market_type = "spot"
  }

  dynamic "iam_instance_profile" {
    for_each = var.asg-iam-instance-profile != null ? var.asg-iam-instance-profile[*] : []
    content {
      arn = iam_instance_profile.value
    }
  }
}

resource "aws_autoscaling_group" "gitlab-runners" {
  count = var.enabled ? 1 : 0
  name = "gitlab-runners-asg"
  max_size = var.asg-max-size
  min_size = 0
  desired_capacity = 0
  vpc_zone_identifier = var.asg-subnets
  suspended_processes = [ "AZRebalance" ]
  protect_from_scale_in = true
  launch_template {
    id = aws_launch_template.gitlab-runner[0].id
    version = "$Latest"
  }
  lifecycle {
    ignore_changes = [
      desired_capacity
    ]
  }
}

resource "aws_instance" "gitlab_runner" {
  count = var.enabled && var.create-manager && var.auth-token != null ? 1 : 0
  ami           = data.aws_ami.latest_amazon_linux_2023.image_id
  instance_type = var.manager-ec2-type
  iam_instance_profile = aws_iam_instance_profile.gitlab-runner-manager-profile[0].name
  subnet_id = one(var.asg-subnets)
  vpc_security_group_ids = var.manager-security-groups
  # vpc_security_group_ids = [aws_security_group.allow_ssh_docker.id]
  tags = {
    Name = "Gitlab runner autoscaling manager"
  }
  # User data script to install Docker and GitLab Runner
  user_data = <<EOF
#!/bin/bash

yum update -y
yum install -y docker git

curl -L --output /usr/bin/fleeting-plugin-aws https://gitlab.com/gitlab-org/fleeting/fleeting-plugin-aws/-/releases/v0.4.0/downloads/fleeting-plugin-aws-linux-amd64
# Give it permission to execute
chmod +x /usr/bin/fleeting-plugin-aws

# Install GitLab Runner
curl -sL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
yum install -y gitlab-runner

# Create default AWS config file
aws_config=$(cat <<EOF
[default]
region = us-east-1

EOF)

mkdir -p ~/.aws
echo "$aws_config" > ~/.aws/config

runner_config=$(cat <<EOF
[[runners]]
  [runners.docker]
  # Autoscaler config
  [runners.autoscaler]
    plugin = "fleeting-plugin-aws"

    capacity_per_instance = 1
    max_use_count = 1
    max_instances = 10

    [runners.autoscaler.plugin_config] # plugin specific configuration (see plugin documentation)
      name             = "${aws_autoscaling_group.gitlab-runners[0].name}" # AWS Autoscaling Group name

    [runners.autoscaler.connector_config]
      username          = "ec2-user"
      use_external_addr = true

    [[runners.autoscaler.policy]]
      idle_count = 0
      idle_time = "20m0s"

EOF)

# Echo the file content and write it to a file
echo "$runner_config" > /tmp/config.toml

# Configure GitLab Runner (replace with your GitLab details)
gitlab-runner register \
  --non-interactive \
  --template-config /tmp/config.toml \
  --url https://gitlab.com \
  --token ${var.auth-token} \
  --executor docker-autoscaler \
  --docker-image alpine:latest \
  --description "My GitLab Runner" \

EOF
}

resource "aws_s3_bucket" "s3_cache" {
  count = var.enabled && var.enable-s3-cache ? 1 : 0
  bucket = "gitlab-shared-cache"
  tags = {
    Service = "Gitlab runner s3 shared cache"
  }
}
