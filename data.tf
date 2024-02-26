data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ami" "latest_amazon_linux_2023" {
  owners       = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  most_recent = true
}

data "aws_ami" "latest_amazon_ecs_linux_2023" {
  owners       = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-2023.*-6.1-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  most_recent = true
}
