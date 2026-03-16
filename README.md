# Valheim Dedicated Server

Self-hosted Valheim server on Hetzner Cloud. Infrastructure is managed with Terraform and deployed via GitHub Actions. The world save lives on a persistent block volume so the server can be rebuilt without losing progress. DNS is managed via Cloudflare — the server is always reachable at `valheim.redmist.online`.

## How it works

- **Hetzner CPX31** (~$18/mo) runs the server as a Docker container (`lloesche/valheim-server`)
- **10GB block volume** is attached at `/mnt/valheim-world` — survives server rebuilds
- **Cloud-init** bootstraps the server on first boot: mounts the volume, writes config, starts the container, sets up automated backups
- **Terraform Cloud** stores remote state so GitHub Actions can manage infra without a local state file
- **Cloudflare DNS** automatically updates `valheim.redmist.online` to the new server IP on every deploy

## Developer flow

All infrastructure changes go through a pull request:

1. Create a branch and make your `terraform/` changes
2. Open a PR targeting `main` — **Terraform Plan** runs automatically as a PR check
3. Review the plan diff in the PR's job summary
4. Get approval and merge — **Deploy Valheim Server** runs automatically and applies the plan

For emergencies outside the normal flow, **Manual Deploy Valheim Server** is available via `workflow_dispatch` and requires `infra` environment approval before anything is applied.

## Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| **Terraform Plan** | PR targeting `main` | Runs `terraform plan` and posts the diff to the job summary |
| **Deploy Valheim Server** | Merge to `main` | Runs `terraform apply` — creates or updates infra. Volume and world data always persist. |
| **Manual Deploy Valheim Server** | Manual (`workflow_dispatch`) | Force deploy outside the PR flow. Requires `infra` environment approval. |
| **Destroy Valheim Server** | Manual | Tears everything down including the volume. World data is gone. Type `DESTROY` to confirm. |
| **Power Off Hetzner Server** | Manual | Gracefully stops the container then powers off the server. Hetzner billing continues. |
| **Power On Hetzner Server** | Manual | Powers the server back on. Container starts automatically. |
| **Restart Valheim Container** | Manual | Restarts the Docker container without touching the server. |
| **Backup: Snapshot** | Manual / daily at 6am | Triggers a backup on the server and downloads it as a GitHub artifact (90 day retention). Artifact names include world name and timestamp. |
| **Backup: Restore** | Manual | Restores a named GitHub artifact to the server. Lists available artifacts on failure. |
| **World: Import from Release** | Manual | Imports an external world save from a GitHub Release. Validates archive, auto-renames world files to match server config. Requires `infra` approval. |
| **Server Status** | Manual | Shows Hetzner server state, IP, container status, and memory. |

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

**5. GitHub Environment**
- Repo → Settings → Environments → **New environment**, name it `infra`
- Under **Deployment protection rules**, enable **Required reviewers** and add yourself
- This gates the Manual Deploy workflow behind an approval step

**6. GitHub secrets and variables** (repo → Settings → Secrets and variables → Actions)

Secrets:

| Secret | Description |
|---|---|
| `TF_TOKEN_APP_TERRAFORM_IO` | Terraform Cloud user token |
| `HCLOUD_TOKEN` | Hetzner API token |
| `SSH_PUBLIC_KEY` | SSH public key content |
| `SSH_PRIVATE_KEY` | SSH private key content |
| `SERVER_PASS` | Server password (min 5 characters) |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token |
| `DISCORD_WEBHOOK_URL` | Discord channel webhook for server notifications |

Variables:

| Variable | Description |
|---|---|
| `SERVER_NAME` | Server name shown in the in-game browser |
| `WORLD_NAME` | World save file name |
| `SERVER_HOST` | Server hostname or IP for SSH (e.g. `valheim.redmist.online` or an IP address) |

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

Backups run automatically every 6 hours to `/mnt/valheim-world/backups/`, keeping 7 days of history. World backups are also downloadable as GitHub Actions artifacts via the **Backup: Snapshot** workflow. Artifacts are named with the world name and timestamp (e.g. `valheim-world-RedMist-20260316-1253`) for easy identification.

To restore a backup, run **Backup: Restore** and provide the artifact name. If you enter a wrong name, the workflow will list available artifacts.

To import an external world save (from local play, another server, etc.), create a GitHub Release with a `.tar.gz` containing the `.db` and `.fwl` files, then run **World: Import from Release**. The workflow will automatically rename the world files to match the server's configured `WORLD_NAME`.

## Connecting

Players connect via: `valheim.redmist.online:2456`

The server is public and appears in the in-game server browser. Search for the server name or connect directly using the hostname above.

The DNS record updates automatically on every deploy — no need to share a new IP.

## Discord notifications

The server posts to a Discord channel on key events:

| Event | Message |
|---|---|
| Server ready | "RedMist is online! Connect now." |
| Server stopping | "RedMist is going offline." |

Set the `DISCORD_WEBHOOK_URL` GitHub secret to enable. Create a webhook in Discord under Server Settings → Integrations → Webhooks.
