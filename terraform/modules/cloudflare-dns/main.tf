terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "server" {
  zone_id = var.zone_id
  name    = var.subdomain
  content = var.server_ip
  type    = "A"
  ttl     = var.ttl
  proxied = false
}
