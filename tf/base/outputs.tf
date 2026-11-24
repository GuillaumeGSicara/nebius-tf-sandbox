output "public_ip" {
  description = "Public IPv4 address of the VM."
  # Strips the /32 suffix if the API returns the address in CIDR form.
  value = split("/", nebius_compute_v1_instance.vm.status.network_interfaces[0].public_ip_address.address)[0]
}
