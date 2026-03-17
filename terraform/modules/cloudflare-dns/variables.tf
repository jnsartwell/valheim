variable "zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}

variable "subdomain" {
  description = "DNS subdomain for the server (e.g. 'valheim' → valheim.yourdomain.com)"
  type        = string
}

variable "server_ip" {
  description = "IPv4 address to point the DNS record at"
  type        = string
}

variable "ttl" {
  description = "TTL in seconds for the DNS A record"
  type        = number
  default     = 60
}
