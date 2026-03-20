output "server_ip" {
  description = "Public IP of the Valheim server"
  value       = hcloud_server.valheim.ipv4_address
}
