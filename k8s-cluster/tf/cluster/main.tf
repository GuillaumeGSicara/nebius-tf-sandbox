locals {
  cluster_name = replace(var.name, "_", "-")
}

# The project fixes the region.
data "nebius_iam_v2_project" "this" {
  id = var.project_id
}

resource "nebius_mk8s_v1_cluster" "this" {
  parent_id = var.project_id
  name      = local.cluster_name

  control_plane = {
    subnet_id         = var.subnet_id
    version           = var.k8s_version
    etcd_cluster_size = var.etcd_cluster_size

    # No public_endpoint block = private endpoint only.
    endpoints = var.public_endpoint ? {
      public_endpoint = { allowed_cidrs = var.allowed_cidrs }
    } : {}
  }

  lifecycle {
    precondition {
      condition     = data.nebius_iam_v2_project.this.region == var.region
      error_message = "The project is in region ${data.nebius_iam_v2_project.this.region}, not ${var.region}. Use a project and a subnet of ${var.region}, or change var.region."
    }
    precondition {
      condition     = !var.public_endpoint || length(var.allowed_cidrs) > 0
      error_message = "A public endpoint needs allowed_cidrs (your IP as x.x.x.x/32)."
    }
  }
}

resource "nebius_mk8s_v1_node_group" "gpu" {
  parent_id = nebius_mk8s_v1_cluster.this.id
  name      = "${local.cluster_name}-gpu"

  fixed_node_count = var.node_count
  version          = var.k8s_version

  template = {
    resources = {
      platform = var.platform
      preset   = var.preset
    }

    boot_disk = {
      type           = "NETWORK_SSD"
      size_gibibytes = var.boot_disk_size_gib
    }

    # GPU drivers come preinstalled on the node image.
    gpu_settings = {
      drivers_preset = var.drivers_preset
    }

    # Spot, as in the VM blueprint. Switch to on-demand with preemptible = false.
    preemptible        = var.preemptible ? {} : null
    follows_spot_price = var.preemptible ? {} : null

    service_account_id = var.attach_service_account ? var.service_account_id : null

    network_interfaces = [
      {
        subnet_id         = var.subnet_id
        public_ip_address = var.node_public_ip ? {} : null
      }
    ]
  }
}
