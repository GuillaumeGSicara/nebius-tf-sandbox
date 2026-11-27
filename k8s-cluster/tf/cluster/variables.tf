variable "project_id" {
  description = "Nebius project ID (project-...) the cluster is created in. A project belongs to one region."
  type        = string
}

variable "region" {
  description = "Expected region of the project. Terraform has no region setting: the project fixes it. This value is only checked against the project (plan fails on mismatch)."
  type        = string
  default     = "uk-south1"
}

variable "subnet_id" {
  description = "Subnet ID (vpcsubnet-...) for the control plane and the nodes. Must be in the project's region."
  type        = string

  validation {
    condition     = startswith(var.subnet_id, "vpcsubnet-")
    error_message = "subnet_id must be a subnet ID (vpcsubnet-...), not a network ID (vpcnetwork-...)."
  }
}

variable "service_account_id" {
  description = "ID (serviceaccount-...) of the service account attached to the nodes. Created outside Terraform."
  type        = string
  default     = null
}

variable "attach_service_account" {
  description = "Attach the service account to the nodes. Off by default, as in the VM blueprint."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name of the cluster. The node group is named <name>-gpu."
  type        = string
  default     = "nebius_k8s_starhopper"
}

variable "k8s_version" {
  description = "Kubernetes version (<major>.<minor>) of the control plane and the nodes. null: Nebius default."
  type        = string
  default     = "1.36"
}

variable "etcd_cluster_size" {
  description = "Control plane etcd size (managed by Nebius). 1 is enough for a test, 3 is the default for high availability."
  type        = number
  default     = 1
}

variable "public_endpoint" {
  description = "Expose the Kubernetes API on a public address. false: private endpoint only, reachable from inside the network. Production should use false."
  type        = bool
  default     = true
}

variable "allowed_cidrs" {
  description = "CIDRs allowed to call the public Kubernetes API, e.g. [\"203.0.113.7/32\"]. Required when public_endpoint is true."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.allowed_cidrs, "0.0.0.0/0")
    error_message = "Do not open the Kubernetes API to 0.0.0.0/0."
  }
}

variable "platform" {
  type    = string
  default = "gpu-b300-sxm"
}

variable "preset" {
  type    = string
  default = "1gpu-24vcpu-346gb"
}

variable "node_count" {
  description = "Number of GPU nodes in the node group."
  type        = number
  default     = 1
}

variable "drivers_preset" {
  description = "GPU drivers preinstalled by Nebius on the node image (cuda12.8 or cuda13.0). The VM image is ubuntu24.04-cuda13.0."
  type        = string
  default     = "cuda13.0"
}

variable "boot_disk_size_gib" {
  type    = number
  default = 200
}

variable "preemptible" {
  description = "Create preemptible nodes at spot price. Cannot be changed without replacing the nodes."
  type        = bool
  default     = true
}

variable "node_public_ip" {
  description = "Give each node a public IPv4 address (simple egress to pull images and models). false needs a NAT or another egress path."
  type        = bool
  default     = true
}
