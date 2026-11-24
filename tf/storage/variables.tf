variable "project_id" {
  description = "Nebius project ID (project-...). Must be the same project as the VM."
  type        = string
}

variable "name" {
  description = "Disk name. The base layer looks the disk up by this name."
  type        = string
  default     = "nebius-vm-starhopper-models"
}

variable "size_gib" {
  description = "Disk size. Can be increased later, never reduced."
  type        = number
  default     = 500
}

variable "type" {
  type    = string
  default = "NETWORK_SSD"
}
