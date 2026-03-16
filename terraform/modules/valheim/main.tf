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
}

# SSH Key
resource "hcloud_ssh_key" "default" {
  name       = "${var.name}-key"
  public_key = var.ssh_public_key
}

# Firewall
resource "hcloud_firewall" "valheim" {
  name = var.name

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_ssh_ips
  }

  rule {
    direction  = "in"
    protocol   = "udp"
    port       = "2456-2458"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Block volume for world persistence
resource "hcloud_volume" "world" {
  name     = "${var.name}-world"
  size     = 10
  location = var.location
  format   = "ext4"
}

# Server
resource "hcloud_server" "valheim" {
  name        = var.name
  server_type = "cpx31"
  image       = "docker-ce"
  location    = var.location
  labels = {
    managed-by = "terraform"
    project    = "valheim"
    repo       = "jnsartwell.valheim"
  }

  ssh_keys     = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.valheim.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    volume_device       = hcloud_volume.world.linux_device
    server_name         = var.server_name
    world_name          = var.world_name
    server_pass         = var.server_pass
    admin_steam_ids     = var.admin_steam_ids
    discord_webhook_url = var.discord_webhook_url
  })
}

# Attach volume to server
resource "hcloud_volume_attachment" "world" {
  volume_id = hcloud_volume.world.id
  server_id = hcloud_server.valheim.id
  automount = false
}

# DNS record — DNS only (no proxy), Valheim uses UDP
resource "cloudflare_record" "valheim" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  content = hcloud_server.valheim.ipv4_address
  type    = "A"
  ttl     = 60
  proxied = false
}
