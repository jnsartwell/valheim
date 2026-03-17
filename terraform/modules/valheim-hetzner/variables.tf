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

variable "valheim_server_name" {
  description = "Valheim server name shown in the in-game browser"
  type        = string
}

variable "valheim_world_name" {
  description = "Valheim world save file name"
  type        = string
}

variable "valheim_server_pass" {
  description = "Valheim server password (min 5 characters)"
  type        = string
  sensitive   = true
}

variable "valheim_admin_ids" {
  description = "Steam 64-bit IDs of Valheim server admins"
  type        = list(string)
}

variable "discord_webhook_url" {
  description = "Discord webhook URL for server notifications"
  type        = string
  sensitive   = true
}

variable "server_type" {
  description = "Hetzner server type (e.g. 'cpx31', 'cpx41')"
  type        = string
}

variable "volume_size" {
  description = "Size of the persistent world volume in GB"
  type        = number
}

