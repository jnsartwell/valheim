variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Edit zone DNS permissions"
  type        = string
  sensitive   = true
}


variable "ssh_public_key" {
  description = "SSH public key to authorize on the server"
  type        = string
}

variable "allowed_ssh_ips" {
  description = "IP ranges allowed to SSH into the server"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "server_name" {
  description = "Valheim server name shown in the server browser"
  type        = string
  default     = "Valheim Server"
}

variable "world_name" {
  description = "Valheim world name (save file name)"
  type        = string
  default     = "Midgard"
}

variable "server_pass" {
  description = "Valheim server password"
  type        = string
  sensitive   = true
}

variable "admin_steam_ids" {
  description = "Steam 64-bit IDs of server admins"
  type        = list(string)
  default     = ["76561198088427001"]
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for server notifications"
  type        = string
  sensitive   = true
  default     = ""
}


variable "dns_ttl" {
  description = "TTL in seconds for the DNS A record"
  type        = number
  default     = 60
}
