variable "hcp_project_id" {
  description = "HCP Project ID"
  type        = string
}

variable "hcp_organization" {
  description = "HCP Organization ID"
  type        = string
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default = "us-east-1"
}

variable "subnet_ids" {
  type    = list(string)
  description = "List of subnet IDs for the ASG"
  default = []  # placeholder, to be conditionally set in main.tf
}

variable "iam_instance_profile" {
  description = "IAM instance profile name with Vault permissions"
  default     = "vault-instance-profile"
}

variable "instance_type" {
  default = "t3.medium"
  description = "EC2 instance type for Vault nodes"
}

variable "asg_capacity" {
  type        = number
  default     = 3
  description = "Number of Vault instances in the ASG"
}

