terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.95.0" # x-release-please-version
    }
  }
}

provider "proxmox" {
  endpoint  = var.virtual_environment_endpoint
  api_token = var.virtual_environment_token
  insecure = true
  ssh {
    agent    = true
    username = "root"
    password = "#(_)RR1<4||3"

    node {
        name = "kitchen1"
        address = "192.168.0.141"
    }
  }
}