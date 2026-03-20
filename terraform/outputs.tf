output "server_ip" {
  description = "Public IP of the Valheim server"
  value       = module.valheim.server_ip
}

output "hostname" {
  description = "Valheim server hostname (from Cloudflare DNS module)"
  value       = module.dns.hostname
}
