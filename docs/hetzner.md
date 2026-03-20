# Hetzner

The Valheim module creates these Hetzner resources:

- **Server** — runs the Valheim Docker container via cloud-init and file provisioner
- **Firewall** — allows UDP 2456-2458 (Valheim) from anywhere, SSH from configurable IPs
- **SSH key** — registered with Hetzner for server access

## Server types

The default is `cpx31` (4 vCPU, 8 GB RAM, ~$18/mo). Valheim needs at least 4 GB RAM for a smooth experience.

| Type | vCPU | RAM | Monthly cost | Notes |
|---|---|---|---|---|
| `cpx21` | 3 | 4 GB | ~$9/mo | Minimum viable, may lag with many players |
| `cpx31` | 4 | 8 GB | ~$18/mo | Recommended for most servers |
| `cpx41` | 8 | 16 GB | ~$33/mo | Large worlds or high player counts |

Change the server type by setting the `server_type` variable. Changing server type triggers a server rebuild — take a backup first (the deploy workflow does this automatically).

## Locations

Hetzner datacenters:

| Code | Location |
|---|---|
| `ash` | Ashburn, VA (US East) |
| `hil` | Hillsboro, OR (US West) |
| `fsn1` | Falkenstein, Germany |
| `nbg1` | Nuremberg, Germany |
| `hel1` | Helsinki, Finland |

Set via the `location` variable.

## Data directory

World data is stored on the server's local disk at `/opt/valheim/data`:

```
/opt/valheim/data/
├── worlds_local/          # World save files (.db, .fwl)
├── backups/               # On-demand backup archives
└── adminlist.txt          # Server admin Steam IDs
```

Since this is local storage (not a persistent volume), server recreates wipe game data. The deploy workflow takes a pre-deploy backup artifact automatically. Use the Restore workflow to recover after a recreate.

## SSH access

The server is accessible via SSH as `root`:

```bash
ssh root@<server-ip>
```

By default, SSH is open to all IPs (for GitHub Actions compatibility). Restrict access by setting `allowed_ssh_ips`:

```hcl
allowed_ssh_ips = ["203.0.113.0/24"]
```

## Cloud-init and provisioners

The server is bootstrapped in two phases:

1. **Cloud-init** (first boot) — tunes kernel settings, writes the `.env` file, and creates the data directory with the admin list
2. **File provisioner** (after cloud-init completes) — copies scripts and compose file from `terraform/server-scripts/` to `/opt/valheim/scripts/`, then starts the container

Helper scripts on the server:

| Script | Purpose |
|---|---|
| `/opt/valheim/scripts/start.sh` | Start the container |
| `/opt/valheim/scripts/stop.sh` | Graceful stop (60s timeout) |
| `/opt/valheim/scripts/backup.sh` | On-demand backup of active world |

For details on how cloud-init templating works, see [Cloud-Init](cloud-init.md).
