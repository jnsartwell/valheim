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

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "subdomain" {
  description = "DNS subdomain for the server (e.g. 'valheim' → valheim.yourdomain.com)"
  type        = string
  default     = "valheim"
}


variable "name" {
  description = "Base name for Hetzner resources (server, firewall, SSH key)"
  type        = string
  default     = "valheim"
}

variable "location" {
  description = "Hetzner datacenter location (e.g. 'ash', 'fsn1', 'nbg1')"
  type        = string
  default     = "ash"
}

variable "server_type" {
  description = "Hetzner server type (e.g. 'cpx31', 'cpx41')"
  type        = string
  default     = "cpx31"
}

variable "ssh_private_key" {
  description = "SSH private key for provisioner connections"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key to authorize on the server"
  type        = string
}

variable "allowed_ssh_ips" {
  description = "IP ranges allowed to SSH into the server (open by default for GitHub Actions workflows)"
  type        = list(string)
  default     = ["0.0.0.0/0", "::/0"]
}

variable "valheim_server_name" {
  description = "Valheim server name shown in the in-game browser"
  type        = string
  default     = "Valheim Server"
}

variable "valheim_server_pass" {
  description = "Valheim server password (min 5 characters)"
  type        = string
  sensitive   = true
}

variable "valheim_admin_ids" {
  description = "Steam 64-bit IDs of Valheim server admins"
  type        = list(string)
  default     = []
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
