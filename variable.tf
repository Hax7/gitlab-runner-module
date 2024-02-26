variable "auth-token" {
  type = string
  description = "Gitalb runner authentication token"
  default = null
}

variable "enabled" {
  type = bool
  default = true
  description = "Enable or disable the module and its resources"
}

variable "asg-max-size" {
  type = number
  description = "Maximum size of instances"
}

variable "vpc_id" {
  type = string
  description = "VPC ID"
  default = ""
}

variable "asg-subnets" {
  type = list(string)
  description = "Subnets where to create autoscaled instances"
}

variable "create-manager" {
  type = bool
  description = "Either to create gitlab runner docker autoscaller ec2 or not, If you disable this make sure to have self-host runner already running to configure with docker autoscaller auto scaling group"
  default = true
}

variable "manager-ec2-type" {
  type = string
  description = "Gitlab runner manager ec2 instance type"
  default = "t2.small"
}

variable "asg-runners-ami" {
  type = string
  description = "AMI used in ASG launch template to scale out runners, MUST HAVE DOCKER ENGINE INSTALLED"
  default = null
}

variable "asg-runners-ec2-type" {
  type = string
  description = "EC2 instance type for scaled out runners"
  default = "t2.medium"
}

variable "asg-security-groups" {
  type = list(string)
  description = "Security Groups of autoscaled runners"
  default = null
}

variable "manager-security-groups" {
  type = list(string)
  description = "Security Groups of gitlab manager runner"
  default = null
}

variable "asg-iam-instance-profile" {
  type = string
  description = "IAM instance profile for autoscaled runners"
  default = null
}

variable "enable-s3-cache" {
  type = bool
  description = "Enable s3 cache or not"
  default = true
}