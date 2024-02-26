locals {
  asg-runners-ami = var.asg_runners_ami != null ? var.asg_runners_ami : data.aws_ami.latest_amazon_ecs_linux_2023.id
  concurrent-limit = var.asg_max_size * var.capacity_per_instance
}