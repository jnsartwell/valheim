variable "hcloud_token" {
  description = "Hetzner Cloud API token"
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

variable "location" {
  description = "Hetzner datacenter location"
  type        = string
  default     = "ash"
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
  description = "Valheim server password (min 5 characters)"
  type        = string
  sensitive   = true
}
