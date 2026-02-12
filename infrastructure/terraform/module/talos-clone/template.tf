resource "proxmox_virtual_environment_vm" "talos_template" {
  name      = "talos-template"
  node_name = var.virtual_environment_node_name

  template = true

  machine     = "q35"
  migrate     = true
  bios        = "seabios"
  description = "Managed by Terraform"
  reboot = true

  agent {
    enabled = true
  }
  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 2048
    floating = 2048
  }
  boot_order = ["scsi0", "net0"]

  efi_disk {
    datastore_id = var.datastore_id
    type         = "4m"
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = proxmox_virtual_environment_file.talos_bare_metal_image.id
    interface    = "scsi0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
  operating_system {
    type = "l26"
  }

  network_device {
    enabled = true
    model = "virtio"
    bridge = "vmbr0"
  }

}

# This downloads the ISO to your machine/runner first
resource "terraform_data" "download_talos" {
  provisioner "local-exec" {
    command = "curl -L -o talos-v1.12.0.iso https://factory.talos.dev/image/2c97492bf124203fa1190e81e7d6197961338d996b0ffcca8caba253c0c21896/v1.12.1/metal-amd64.iso"
  }
}

# This pushes the local file to Proxmox
resource "proxmox_virtual_environment_file" "talos_bare_metal_image" {
  depends_on   = [terraform_data.download_talos]
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.virtual_environment_node_name

  source_file {
    path = "talos-v1.12.0.iso"
    file_name = "talos-v1.12.0-amd64.iso"
  }
}