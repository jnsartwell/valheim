terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
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
  size     = var.volume_size
  location = var.location
  format   = "ext4"
}

# Server
resource "hcloud_server" "valheim" {
  name        = var.name
  server_type = var.server_type
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
    valheim_server_name = var.valheim_server_name
    valheim_world_name  = var.valheim_world_name
    valheim_server_pass = var.valheim_server_pass
    valheim_admin_ids   = var.valheim_admin_ids
    discord_webhook_url = var.discord_webhook_url
  })
}

# Attach volume to server
resource "hcloud_volume_attachment" "world" {
  volume_id = hcloud_volume.world.id
  server_id = hcloud_server.valheim.id
  automount = false
}
