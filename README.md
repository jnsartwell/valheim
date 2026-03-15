# Valheim Dedicated Server

Self-hosted Valheim server on Hetzner Cloud. Infrastructure is managed with Terraform and deployed via GitHub Actions. The world save lives on a persistent block volume so the server can be destroyed and recreated without losing progress.

## How it works

- **Hetzner CPX31** (~$18/mo) runs the server as a Docker container (`lloesche/valheim-server`)
- **10GB block volume** is attached at `/mnt/valheim-world` — survives server destroy/recreate
- **Cloud-init** bootstraps the server on first boot: mounts the volume, writes config, starts the container, sets up automated backups
- **Terraform Cloud** stores remote state so GitHub Actions can manage infra without a local state file

## Deploying

All infra is managed through GitHub Actions — no local Terraform needed after setup.

**Actions → Deploy Valheim Server** — creates the Hetzner server, volume, firewall, and starts Valheim. Outputs the server IP when done.

**Actions → Destroy Valheim Server** — tears everything down (type `DESTROY` to confirm). The world volume is also destroyed, so make sure you have a backup first.

## One-time setup

**1. Terraform Cloud** (app.terraform.io)
- Create a free account and organization
- Update `terraform/backend.tf` with your organization name
- Create a user API token → `TF_TOKEN_APP_TERRAFORM_IO` GitHub secret
- Set the workspace **Execution Mode** to **Local**

**2. Hetzner**
- Create an API token (Read & Write) → `HCLOUD_TOKEN` GitHub secret

**3. SSH key**
- Generate a key pair: `ssh-keygen -t ed25519 -C "valheim"`
- Add the public key content → `SSH_PUBLIC_KEY` GitHub secret
- Keep the private key locally to SSH into the server after deploy

**4. GitHub secrets** (repo → Settings → Secrets and variables → Actions)

| Secret | Description |
|---|---|
| `HCLOUD_TOKEN` | Hetzner API token |
| `SSH_PUBLIC_KEY` | SSH public key content |
| `SERVER_NAME` | Server name shown in the browser |
| `WORLD_NAME` | World save file name |
| `SERVER_PASS` | Server password (min 5 characters) |
| `TF_TOKEN_APP_TERRAFORM_IO` | Terraform Cloud user token |

## After deploying

SSH into the server:
```
ssh root@<ip shown in Actions output>
```

Useful commands on the server:
```bash
docker logs -f valheim          # live server logs
/opt/valheim/scripts/stop.sh    # graceful stop
/opt/valheim/scripts/start.sh   # start
```

Backups run automatically every 6 hours to `/mnt/valheim-world/backups/`, keeping 7 days of history.
