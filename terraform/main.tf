terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.47.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "hcp" {

}

data "aws_ami" "vault" {
  most_recent = true
  owners      = ["self"] # or use your AWS account ID

  filter {
    name   = "name"
    values = ["vault-ami-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}


data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_iam_role" "vault" {
  name = "vault-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vault_attach" {
  role       = aws_iam_role.vault.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore" // adjust as needed
}

resource "aws_iam_instance_profile" "vault" {
  name = "vault-instance-profile"
  role = aws_iam_role.vault.name
}

resource "aws_launch_template" "vault_lt" {
  name_prefix   = "vault-node-"
  image_id = data.aws_ami.vault.id
  instance_type = var.instance_type

  # Render vault config on boot
  user_data = base64encode(<<EOF
#!/bin/bash
/usr/local/bin/render-vault-config.sh
EOF
  )

  iam_instance_profile {
  name = aws_iam_instance_profile.vault.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Role = "vault"
    }
  }
}

resource "aws_autoscaling_group" "vault_asg" {
  desired_capacity = var.asg_capacity
  max_size        = var.asg_capacity
  min_size        = var.asg_capacity
  vpc_zone_identifier = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.default.ids


  launch_template {
    id      = aws_launch_template.vault_lt.id
    version = "$Latest"
  }

  health_check_type = "EC2"
}

