# Create multiple nodes (master + workers) from the template
resource "proxmox_virtual_environment_vm" "talos_nodes" {
  for_each = var.nodes

  node_name = var.virtual_environment_node_name
  name      = each.key
  
  started = true

  clone {
    vm_id = proxmox_virtual_environment_vm.talos_template.vm_id
    full  = true
  }
}

# Output all created VMs
output "nodes" {
  value = {
    for name, vm in proxmox_virtual_environment_vm.talos_nodes : name => {
      vm_id = vm.vm_id
      type  = var.nodes[name].type
    }
  }
  description = "Created Talos cluster nodes"
}

output "master_nodes" {
  value = {
    for name, vm in proxmox_virtual_environment_vm.talos_nodes : name => vm.vm_id
    if var.nodes[name].type == "master"
  }
  description = "Master node IDs"
}

output "worker_nodes" {
  value = {
    for name, vm in proxmox_virtual_environment_vm.talos_nodes : name => vm.vm_id
    if var.nodes[name].type == "worker"
  }
  description = "Worker node IDs"
}
