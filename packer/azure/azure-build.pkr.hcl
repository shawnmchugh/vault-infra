packer {
  required_plugins {
    azure-arm = {
      version = ">= 1.6.0"
      source  = "github.com/hashicorp/azure"
    }
    ansible = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# Packer config for Azure
source "azure-arm" "vault" {
  client_id       = var.azure_client_id
  client_secret   = var.azure_client_secret
  tenant_id       = var.azure_tenant_id
  subscription_id = var.azure_subscription_id

  managed_image_name              = "vault-azure-{{timestamp}}"
  managed_image_resource_group   = var.azure_resource_group
  managed_image_location         = var.azure_location
  os_type                        = "Linux"
  image_publisher                = "RedHat"
  image_offer                    = "RHEL"
  image_sku                      = "9-lvm"
  azure_tags = {
    source = "packer"
  }
  location = var.azure_location
  vm_size  = "Standard_B2s"
  build_platform = "azure"
}

build {
  name = "vault-with-agents"
  sources = ["source.azure-arm.vault"]

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
      "--extra-vars", "platform=azure"
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

