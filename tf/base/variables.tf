variable "project_id" {
  description = "Nebius project ID (project-...) the VM is created in."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID (vpcsubnet-...) the VM is attached to."
  type        = string

  validation {
    condition     = startswith(var.subnet_id, "vpcsubnet-")
    error_message = "subnet_id must be a subnet ID (vpcsubnet-...), not a network ID (vpcnetwork-...)."
  }
}

variable "service_account_id" {
  description = "ID (serviceaccount-...) of the service account attached to the VM. Created outside Terraform."
  type        = string
}

variable "attach_service_account" {
  description = "Attach the service account to the VM. Off by default: the Terraform service account is not allowed to attach itself."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name shared by the VM and its admin user."
  type        = string
  default     = "nebius_vm_starhopper"
}

variable "ssh_public_key_path" {
  description = "Public key authorized for the admin user."
  type        = string
  default     = "~/.ssh/nebius_vm_starhopper.pub"
}

variable "platform" {
  type    = string
  default = "gpu-b300-sxm"
}

variable "preset" {
  type    = string
  default = "1gpu-24vcpu-346gb"
}

variable "image_family" {
  type    = string
  default = "ubuntu24.04-cuda13.0"
}

variable "boot_disk_size_gib" {
  type    = number
  default = 200
}

variable "preemptible" {
  description = "Create a preemptible VM at spot price. Cannot be changed without replacing the VM."
  type        = bool
  default     = true
}

variable "models_disk_name" {
  description = "Name of the disk holding model weights (created by the storage layer)."
  type        = string
  default     = "nebius-vm-starhopper-models"
}

variable "models_mount_path" {
  type    = string
  default = "/mnt/models"
}
