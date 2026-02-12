variable "virtual_environment_endpoint" {
  type        = string
  description = "The endpoint for the Proxmox Virtual Environment API (example: https://host:port)"
}

variable "virtual_environment_token" {
  type        = string
  description = "The token for the Proxmox Virtual Environment API"
  sensitive   = true
}

variable "virtual_environment_node_name" {
  type        = string
  description = "The node name for the Proxmox Virtual Environment API"
  default     = "kitchen1"
}

variable "datastore_id" {
  type        = string
  description = "Datastore for VM disks"
  default     = "local-lvm"
}

variable "nodes" {
  type = map(object({
    type   = string # "master" or "worker"
    memory = number
    cores  = number
  }))
  description = "Configuration for cluster nodes"
  default = {
    "master-0" = {
      type   = "master"
      memory = 4096
      cores  = 4
    }
    "worker-0" = {
      type   = "worker"
      memory = 2048
      cores  = 2
    }
    "worker-1" = {
      type   = "worker"
      memory = 2048
      cores  = 2
    }
    "worker-2" = {
      type   = "worker"
      memory = 2048
      cores  = 2
    }
  }
}