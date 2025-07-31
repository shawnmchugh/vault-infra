packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "amazon-ebs" "vault" {
  region           = "us-east-1"
  instance_type    = "t3.medium"
  ssh_username     = "ec2-user"

  source_ami_filter {
    filters = {
      name                  = "RHEL-9*"
      virtualization-type   = "hvm"
      root-device-type      = "ebs"
      architecture          = "x86_64"

    }
    owners      = ["309956199498"] # Official Red Hat AMIs
    most_recent = true
  }

  ami_name = "vault-ami-{{timestamp}}"
}

build {
  name = "vault-with-agents"
  sources = [ "source.amazon-ebs.vault" ]

  provisioner "shell" {
    inline = [
      "sudo dnf install -y python3.11 || sudo yum install -y python3.11",
      "sudo alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1",
      "sudo ln -sf /usr/bin/python3.11 /usr/bin/python || true"
    ]
    execute_command = "sudo -E /bin/sh -c '{{ .Vars }} {{ .Path }}'"
  }

  provisioner "ansible" {
    playbook_file = "../ansible/packer.yml"
    extra_arguments = [
      "--extra-vars", "platform=aws"
    ]
  }
}

hcp_packer_registry {
  bucket_name   = "vault-images"
  description   = "Vault dev node image"
  bucket_labels = {
    os    = "rhel"
    role  = "vault"
  }
  build_labels = {
    environment = "dev"
  }
}

