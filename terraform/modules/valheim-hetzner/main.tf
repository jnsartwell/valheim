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
    valheim_server_name = var.valheim_server_name
    valheim_world_name  = var.valheim_world_name
    valheim_server_pass = var.valheim_server_pass
    valheim_admin_ids   = var.valheim_admin_ids
    discord_webhook_url = var.discord_webhook_url
  })

  connection {
    type        = "ssh"
    user        = "root"
    private_key = var.ssh_private_key
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait || [ $? -eq 2 ]",
      "cloud-init status --long"
    ]
  }

  provisioner "file" {
    source      = "${path.root}/server-scripts/"
    destination = "/opt/valheim/scripts/"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /opt/valheim/scripts/*.sh",
      "docker compose -f /opt/valheim/scripts/compose.yaml --env-file /opt/valheim/docker/.env up -d"
    ]
  }
}
