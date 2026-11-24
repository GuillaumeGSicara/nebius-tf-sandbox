locals {
  models_device_id = "models"
}

# Created by the storage layer.
data "nebius_compute_v1_disk" "models" {
  parent_id = var.project_id
  name      = var.models_disk_name
}

resource "nebius_compute_v1_instance" "vm" {
  parent_id = var.project_id
  # Hyphenated: the VM name is also used as hostname, where underscores are invalid.
  name = replace(var.name, "_", "-")

  service_account_id = var.attach_service_account ? var.service_account_id : null

  # Preemptible VMs only support the FAIL recovery policy.
  preemptible        = var.preemptible ? { on_preemption = "STOP" } : null
  follows_spot_price = var.preemptible ? {} : null
  recovery_policy    = var.preemptible ? "FAIL" : null

  resources = {
    platform = var.platform
    preset   = var.preset
  }

  boot_disk = {
    attach_mode = "READ_WRITE"
    managed_disk = {
      name = "${replace(var.name, "_", "-")}-boot"
      spec = {
        type           = "NETWORK_SSD"
        size_gibibytes = var.boot_disk_size_gib
        source_image_family = {
          image_family = var.image_family
        }
      }
    }
  }

  network_interfaces = [
    {
      name       = "eth0"
      subnet_id  = var.subnet_id
      ip_address = {}
      # Static: the address survives stop/start, including preemption.
      public_ip_address = { static = true }
    }
  ]

  secondary_disks = [
    {
      attach_mode   = "READ_WRITE"
      device_id     = local.models_device_id
      existing_disk = { id = data.nebius_compute_v1_disk.models.id }
    }
  ]

  cloud_init_user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    username       = var.name
    models_device  = "/dev/disk/by-id/virtio-${local.models_device_id}"
    mount_path     = var.models_mount_path
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })
}
