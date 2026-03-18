# Getting Started

Deploy a Valheim dedicated server on Hetzner Cloud with a single `terraform apply`. World data persists on a block volume so you can rebuild the server without losing progress.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.9
- A [Hetzner Cloud](https://www.hetzner.com/cloud/) account
- An SSH key pair (`ssh-keygen -t ed25519`)

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/jnsartwell/valheim-hetzner-iac.git
cd valheim-hetzner-iac/terraform
```

### 2. Configure the backend

Edit `backend.tf` with your Terraform Cloud organization, or replace it with a local backend:

```hcl
terraform {
  backend "local" {}
}
```

### 3. Set your variables

Create a `terraform.tfvars` file:

```hcl
hcloud_token   = "your-hetzner-api-token"
ssh_public_key = "ssh-ed25519 AAAA..."
valheim_server_pass = "your-server-password"  # min 5 characters
```

That's all you need for a basic deployment. See [Optional features](#optional-features) for DNS and Discord.

### 4. Deploy

```bash
terraform init
terraform plan
terraform apply
```

Terraform creates a Hetzner server running the [lloesche/valheim-server](https://github.com/lloesche/valheim-server-docker) Docker image with a persistent block volume for world data.

### 5. Connect

After deploy, Terraform outputs the server IP:

```
server_ip = "203.0.113.42"
```

Connect in Valheim via: `203.0.113.42:2456`

## Optional features

### Cloudflare DNS

Point a domain at your server so players don't need to remember an IP. See [Cloudflare DNS](cloudflare-dns.md).

### Discord notifications

Get notified in a Discord channel when the server comes online or goes offline. See [Discord Notifications](discord.md).

## Variables reference

| Variable | Required | Default | Description |
|---|---|---|---|
| `hcloud_token` | Yes | — | Hetzner Cloud API token |
| `ssh_public_key` | Yes | — | SSH public key to authorize on the server |
| `valheim_server_pass` | Yes | — | Valheim server password (min 5 characters) |
| `name` | No | `valheim` | Base name for Hetzner resources |
| `location` | No | `ash` | Hetzner datacenter location |
| `server_type` | No | `cpx31` | Hetzner server type |
| `volume_size` | No | `10` | Persistent volume size in GB |
| `valheim_server_name` | No | `Valheim Server` | Name shown in the in-game server browser |
| `valheim_world_name` | No | `Midgard` | World save file name (hardcoded in `main.tf` for world switching) |
| `valheim_admin_ids` | No | `[]` | Steam 64-bit IDs of server admins |
| `allowed_ssh_ips` | No | `["0.0.0.0/0", "::/0"]` | IP ranges allowed to SSH in |
| `discord_webhook_url` | No | `""` | Discord webhook URL (enables notifications) |

See also: [Hetzner](hetzner.md) for server types and volume details.

## Next steps

- [World Management](world-management.md) — upload new worlds and switch between them
- [Backups](backups.md) — automatic and manual backup options
- [GitHub Actions](github-actions.md) — CI/CD workflows for PR-based deploys
