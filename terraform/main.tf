terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  required_version = ">= 1.9"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "valheim" {
  source = "./modules/valheim-hetzner"

  name            = var.name
  location        = var.location
  ssh_public_key  = var.ssh_public_key
  allowed_ssh_ips = var.allowed_ssh_ips

  valheim_server_name = var.valheim_server_name
  valheim_world_name  = "Panthera"
  valheim_server_pass = var.valheim_server_pass
  valheim_admin_ids   = var.valheim_admin_ids
  discord_webhook_url = var.discord_webhook_url

  server_type = var.server_type
  volume_size = var.volume_size
}

# Cloudflare DNS — optional, remove this block and the cloudflare provider to skip DNS
module "dns" {
  source = "./modules/cloudflare-dns"

  zone_id   = var.cloudflare_zone_id
  subdomain = var.subdomain
  server_ip = module.valheim.server_ip
  ttl       = var.dns_ttl
}

