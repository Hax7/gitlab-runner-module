variable "auth-token" {
  type = string
  description = "Gitalb runner authentication token"
  default = ""
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