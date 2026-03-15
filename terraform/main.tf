terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.49"
    }
  }

  required_version = ">= 1.9"
}

provider "hcloud" {
  token = var.hcloud_token
}

# SSH Key
resource "hcloud_ssh_key" "default" {
  name       = "valheim-key"
  public_key = var.ssh_public_key
}

# Firewall
resource "hcloud_firewall" "valheim" {
  name = "valheim"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = var.allowed_ssh_ips
  }

  rule {
    direction = "in"
    protocol  = "udp"
    port      = "2456-2458"
    source_ips = ["0.0.0.0/0", "::/0"]
  }
}

# Block volume for world persistence
resource "hcloud_volume" "world" {
  name      = "valheim-world"
  size      = 10
  location  = var.location
  format    = "ext4"
}

# Server
resource "hcloud_server" "valheim" {
  name        = "valheim"
  server_type = "cpx31"
  image       = "docker-ce"
  location    = var.location

  ssh_keys    = [hcloud_ssh_key.default.id]
  firewall_ids = [hcloud_firewall.valheim.id]

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    volume_device = hcloud_volume.world.linux_device
    server_name   = var.server_name
    world_name    = var.world_name
    server_pass   = var.server_pass
  })
}

# Attach volume to server
resource "hcloud_volume_attachment" "world" {
  volume_id = hcloud_volume.world.id
  server_id = hcloud_server.valheim.id
  automount = true
}
