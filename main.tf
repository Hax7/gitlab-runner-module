resource "aws_iam_policy" "gitlab-runner-manager-policy" {
  count = var.enabled ? 1 : 0
  name = "docker-autoscaler"
  policy = templatefile("${path.module}/policies/instance-docker-autoscaler-policy.json",
    {
      autoscaling_group_arn = aws_autoscaling_group.gitlab-runners[0].arn
      autoscaling_group_name = aws_autoscaling_group.gitlab-runners[0].name
      aws_region = data.aws_region.current.name
      aws_account_id = data.aws_caller_identity.current.account_id
    })
}

resource "aws_iam_role" "gitlab-runner" {
  count = var.enabled ? 1 : 0
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
  managed_policy_arns =  [aws_iam_policy.gitlab-runner-manager-policy[0].arn] 
}

resource "aws_launch_template" "gitlab-runner" {
  count = var.enabled ? 1 : 0
  name = "gitlab-runner-template"
  image_id = "ami-0440d3b780d96b29d"
  instance_type = "t2.micro"

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
}

resource "aws_instance" "gitlab_runner" {
  ami           = "ami-0440d3b780d96b29d" # Replace with the latest Amazon Linux 2023 AMI
  instance_type = "t2.micro" # Adjust instance type based on your needs
  # vpc_security_group_ids = [aws_security_group.allow_ssh_docker.id]

  # User data script to install Docker and GitLab Runner
  user_data = <<EOF
#!/bin/bash

yum update -y
yum install -y docker git

# Install GitLab Runner
curl -sL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh" | sudo bash
yum install -y gitlab-runner

# Configure GitLab Runner (replace with your GitLab details)
gitlab-runner register \
  --url https://gitlab.com \
  --token ${var.auth-token} \
  --executor docker-autoscaler \
  --docker-image alpine:latest \
  --description "My GitLab Runner" \

# Start GitLab Runner service
systemctl start gitlab-runner

EOF
}
