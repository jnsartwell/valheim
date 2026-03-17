output "server_ip" {
  description = "Public IP of the Valheim server"
  value       = module.valheim.server_ip
}

output "volume_device" {
  description = "Block device path for the world volume"
  value       = module.valheim.volume_device
}

output "hostname" {
  description = "Valheim server hostname (from Cloudflare DNS module)"
  value       = module.dns.hostname
}
