output "cluster_id" {
  description = "ID of the Managed Kubernetes cluster."
  value       = nebius_mk8s_v1_cluster.this.id
}

output "public_endpoint" {
  description = "Public Kubernetes API address (empty when the endpoint is private)."
  value       = try(nebius_mk8s_v1_cluster.this.status.control_plane.endpoints.public_endpoint, null)
}

output "private_endpoint" {
  description = "Private Kubernetes API address."
  value       = try(nebius_mk8s_v1_cluster.this.status.control_plane.endpoints.private_endpoint, null)
}

output "get_credentials_command" {
  description = "Command that writes the kubeconfig."
  value       = "nebius mk8s cluster get-credentials --id ${nebius_mk8s_v1_cluster.this.id} ${var.public_endpoint ? "--external" : "--internal"}"
}

output "cluster_ca_certificate" {
  description = "CA certificate of the Kubernetes API (public, not a secret)."
  value       = try(nebius_mk8s_v1_cluster.this.status.control_plane.auth.cluster_ca_certificate, null)
}
