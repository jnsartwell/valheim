# Valheim Dedicated Server on Hetzner Cloud

Terraform module for running a [Valheim](https://www.valheimgame.com/) dedicated server on Hetzner Cloud. World data persists on a block volume so the server can be rebuilt without losing progress.

## What you get

- **Hetzner server** running the [lloesche/valheim-server](https://github.com/lloesche/valheim-server-docker) Docker image
- **Persistent block volume** for world saves — survives server rebuilds
- **Automated backups** every 6 hours with 7-day retention
- **Firewall** with Valheim ports (UDP 2456-2458) and configurable SSH access
- **Cloud-init** bootstraps everything on first boot — no manual server setup

### Optional

- **[Cloudflare DNS](docs/cloudflare-dns.md)** — hostname for your server (e.g. `valheim.example.com`)
- **[Discord notifications](docs/discord.md)** — channel alerts when the server comes online or goes offline
- **[GitHub Actions](docs/github-actions.md)** — PR-gated deploys, operational workflows, offsite backups

## Quick start

```bash
git clone https://github.com/jnsartwell/valheim-hetzner-iac.git
cd valheim-hetzner-iac/terraform
```

Create `terraform.tfvars`:

```hcl
hcloud_token   = "your-hetzner-api-token"
ssh_public_key = "ssh-ed25519 AAAA..."
valheim_server_pass = "your-server-password"
```

```bash
terraform init
terraform apply
```

Connect in Valheim using the `server_ip` output: `<ip>:2456`

See **[Getting Started](docs/getting-started.md)** for the full walkthrough.

## Documentation

| Topic | Description |
|---|---|
| [Getting Started](docs/getting-started.md) | Full setup walkthrough and variables reference |
| [Hetzner](docs/hetzner.md) | Server types, volumes, locations, SSH access |
| [Cloudflare DNS](docs/cloudflare-dns.md) | Optional hostname with Cloudflare |
| [Discord Notifications](docs/discord.md) | Optional Discord webhook alerts |
| [Backups](docs/backups.md) | Automatic backups, manual snapshots, restore, world import |
| [GitHub Actions](docs/github-actions.md) | CI/CD workflows, secrets, and environment setup |
| [Cloud-Init](docs/cloud-init.md) | How server bootstrapping works, template escaping rules |

## Connecting

After deploying, players connect via the server IP or hostname:

```
<server-ip>:2456          # direct IP
valheim.example.com:2456  # if using Cloudflare DNS
```

The server is public and appears in the in-game server browser.

## After deploying

SSH into the server:

```bash
ssh root@<server-ip>
```

Useful commands:

```bash
docker logs -f valheim                # live server logs
/opt/valheim/scripts/stop.sh          # graceful stop
/opt/valheim/scripts/start.sh         # start
/opt/valheim/scripts/backup.sh        # manual backup
```
