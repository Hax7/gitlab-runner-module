locals {
  asg-runners-ami = var.asg-runners-ami != null ? var.asg-runners-ami : data.aws_ami.latest_amazon_ecs_linux_2023.id
}