variable "name" {
  description = "Base name used for Hetzner resource naming (e.g. 'valheim', 'bifrost')"
  type        = string
}

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key to authorize on the server"
  type        = string
}

variable "allowed_ssh_ips" {
  description = "IP ranges allowed to SSH into the server"
  type        = list(string)
}

variable "server_name" {
  description = "Valheim server name shown in the server browser"
  type        = string
}

variable "world_name" {
  description = "Valheim world name (save file name)"
  type        = string
}

variable "server_pass" {
  description = "Valheim server password"
  type        = string
  sensitive   = true
}

variable "admin_steam_ids" {
  description = "Steam 64-bit IDs of server admins"
  type        = list(string)
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for server notifications"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "subdomain" {
  description = "DNS subdomain for the server (e.g. 'valheim' → valheim.redmist.online)"
  type        = string
}

variable "server_type" {
  description = "Hetzner server type (e.g. 'cpx31', 'cpx41')"
  type        = string
}

variable "volume_size" {
  description = "Size of the persistent world volume in GB"
  type        = number
}

variable "dns_ttl" {
  description = "TTL in seconds for the DNS A record"
  type        = number
}
