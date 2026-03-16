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

module "redmist" {
  source = "./modules/valheim"

  name            = "valheim"
  location        = "ash"
  ssh_public_key  = var.ssh_public_key
  allowed_ssh_ips = var.allowed_ssh_ips

  server_name         = var.server_name
  world_name          = var.world_name
  server_pass         = var.server_pass
  admin_steam_ids     = var.admin_steam_ids
  discord_webhook_url = var.discord_webhook_url

  cloudflare_zone_id = "04ef9294de8a84aec07f31302cc3b5f1"
  subdomain          = "valheim"

  server_type = "cpx31"
  volume_size = 10
  dns_ttl     = var.dns_ttl
}

