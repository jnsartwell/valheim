output "server_ip" {
  description = "Public IP of the Valheim server"
  value       = hcloud_server.valheim.ipv4_address
}

output "volume_device" {
  description = "Block device path for the world volume"
  value       = hcloud_volume.world.linux_device
}

