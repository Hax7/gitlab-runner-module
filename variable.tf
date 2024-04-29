variable "auth_token" {
  type        = string
  description = "Gitalb runner authentication token"
  default     = null
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Enable or disable the module and its resources"
}

variable "asg_max_size" {
  type        = number
  description = "Maximum size of instances"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
  default     = ""
}

variable "asg_subnets" {
  type        = list(string)
  description = "Subnets where to create autoscaled instances"
}

variable "create_manager" {
  type        = bool
  description = "Either to create gitlab runner docker autoscaller ec2 or not, If you disable this make sure to have self-host runner already running to configure with docker autoscaller auto scaling group"
  default     = true
}

variable "manager_ec2_type" {
  type        = string
  description = "Gitlab runner manager ec2 instance type"
  default     = "t2.small"
}

variable "asg_runners_ami" {
  type        = string
  description = "AMI used in ASG launch template to scale out runners, MUST HAVE DOCKER ENGINE INSTALLED"
  default     = null
}

variable "asg_runners_ec2_type" {
  type        = string
  description = "EC2 instance type for scaled out runners"
  default     = "t2.medium"
}

variable "asg_security_groups" {
  type        = list(string)
  description = "Security Groups of autoscaled runners"
  default     = null
}

variable "manager_security_groups" {
  type        = list(string)
  description = "Security Groups of gitlab manager runner"
  default     = null
}

variable "asg_iam_instance_profile" {
  type        = string
  description = "IAM instance profile for autoscaled runners"
  default     = null
}

variable "enable_s3_cache" {
  type        = bool
  description = "Enable s3 cache or not"
  default     = true
}

variable "capacity_per_instance" {
  type        = number
  description = "The number of jobs that can be executed concurrently by a single instance."
  default     = 1
}

variable "extra_policy_entries" {
  description = "Optional extra entries to add to the policy"
  type        = map(any)
  default     = null
}
