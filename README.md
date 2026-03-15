# Valheim Dedicated Server

Self-hosted Valheim server on Hetzner Cloud. Infrastructure is managed with Terraform and deployed via GitHub Actions. The world save lives on a persistent block volume so the server can be rebuilt without losing progress. DNS is managed via Cloudflare — the server is always reachable at `valheim.redmist.online`.

## How it works

- **Hetzner CPX31** (~$18/mo) runs the server as a Docker container (`lloesche/valheim-server`)
- **10GB block volume** is attached at `/mnt/valheim-world` — survives server rebuilds
- **Cloud-init** bootstraps the server on first boot: mounts the volume, writes config, starts the container, sets up automated backups
- **Terraform Cloud** stores remote state so GitHub Actions can manage infra without a local state file
- **Cloudflare DNS** automatically updates `valheim.redmist.online` to the new server IP on every deploy

## Workflows

| Workflow | What it does |
|---|---|
| **Deploy Valheim Server** | Creates/rebuilds the server via `terraform apply`. Safe to run anytime — volume and world data persist. |
| **Destroy Valheim Server** | Tears everything down including the volume. World data is gone. Type `DESTROY` to confirm. |
| **Power Off Hetzner Server** | Gracefully stops the container then powers off the server. Hetzner billing continues. |
| **Power On Hetzner Server** | Powers the server back on. Container starts automatically. |
| **Restart Valheim Container** | Restarts the Docker container without touching the server. |
| **Download World Backup** | Triggers a backup on the server and downloads it as a GitHub artifact (90 day retention). |
| **Restore World Backup** | Restores a named GitHub artifact to the server. |
| **Server Status** | Shows Hetzner server state, IP, container status, and memory. |

## One-time setup

**1. Terraform Cloud** (app.terraform.io)
- Create a free account and organization
- Update `terraform/backend.tf` with your organization name
- Create a workspace named `valheim`, set **Execution Mode** to **Local**
- Create a user API token → `TF_TOKEN_APP_TERRAFORM_IO` GitHub secret

**2. Hetzner**
- Create an API token (Read & Write) → `HCLOUD_TOKEN` GitHub secret

**3. Cloudflare**
- Register your domain at a registrar (e.g. Namecheap), point nameservers at Cloudflare
- Add the site to Cloudflare (free plan)
- Create an API token with **Edit zone DNS** permissions scoped to your zone → `CLOUDFLARE_API_TOKEN` GitHub secret
- Update `cloudflare_zone_id` default in `terraform/variables.tf` with your Zone ID

**4. SSH key**
- Generate a key pair: `ssh-keygen -t ed25519 -C "your@email.com"`
- Add the public key content → `SSH_PUBLIC_KEY` GitHub secret
- Add the private key content → `SSH_PRIVATE_KEY` GitHub secret

**5. GitHub secrets** (repo → Settings → Secrets and variables → Actions)

| Secret | Description |
|---|---|
| `TF_TOKEN_APP_TERRAFORM_IO` | Terraform Cloud user token |
| `HCLOUD_TOKEN` | Hetzner API token |
| `SSH_PUBLIC_KEY` | SSH public key content |
| `SSH_PRIVATE_KEY` | SSH private key content |
| `SERVER_NAME` | Server name shown in the browser |
| `WORLD_NAME` | World save file name |
| `SERVER_PASS` | Server password (min 5 characters) |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token |
| `DISCORD_WEBHOOK_URL` | Discord channel webhook for server notifications |

## After deploying

SSH into the server:
```bash
ssh root@valheim.redmist.online
```

Useful commands on the server:
```bash
docker logs -f valheim          # live server logs
/opt/valheim/scripts/stop.sh    # graceful stop
/opt/valheim/scripts/start.sh   # start
/opt/valheim/scripts/backup.sh  # manual backup
```

Backups run automatically every 6 hours to `/mnt/valheim-world/backups/`, keeping 7 days of history. World backups are also downloadable as GitHub Actions artifacts via the **Download World Backup** workflow.

## Connecting

Players connect via: `valheim.redmist.online:2456`

The server is public and appears in the in-game server browser. Search for the server name or connect directly using the hostname above.

The DNS record updates automatically on every deploy — no need to share a new IP.

## Discord notifications

The server posts to a Discord channel on key events:

| Event | Message |
|---|---|
| Server ready | "One Eyes Keep is online! Connect now." |
| Server stopping | "One Eyes Keep is going offline." |

Set the `DISCORD_WEBHOOK_URL` GitHub secret to enable. Create a webhook in Discord under Server Settings → Integrations → Webhooks.
