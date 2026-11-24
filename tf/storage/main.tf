# Model weights. Kept in its own layer so destroying the VM never touches them.
# A disk, not a shared filesystem: the tenant has no shared filesystem quota.
resource "nebius_compute_v1_disk" "models" {
  parent_id      = var.project_id
  name           = var.name
  type           = var.type
  size_gibibytes = var.size_gib
}
