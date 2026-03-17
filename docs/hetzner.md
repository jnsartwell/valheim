# Hetzner

The Valheim module creates these Hetzner resources:

- **Server** — runs the Valheim Docker container via cloud-init
- **Block volume** — persistent storage for world data, mounted at `/mnt/valheim-world`
- **Firewall** — allows UDP 2456-2458 (Valheim) from anywhere, SSH from configurable IPs
- **SSH key** — registered with Hetzner for server access

## Server types

The default is `cpx31` (4 vCPU, 8 GB RAM, ~$18/mo). Valheim needs at least 4 GB RAM for a smooth experience.

| Type | vCPU | RAM | Monthly cost | Notes |
|---|---|---|---|---|
| `cpx21` | 3 | 4 GB | ~$9/mo | Minimum viable, may lag with many players |
| `cpx31` | 4 | 8 GB | ~$18/mo | Recommended for most servers |
| `cpx41` | 8 | 16 GB | ~$33/mo | Large worlds or high player counts |

Change the server type by setting the `server_type` variable. Changing server type triggers a server rebuild — the volume persists so world data is safe.

## Locations

Hetzner datacenters:

| Code | Location |
|---|---|
| `ash` | Ashburn, VA (US East) |
| `hil` | Hillsboro, OR (US West) |
| `fsn1` | Falkenstein, Germany |
| `nbg1` | Nuremberg, Germany |
| `hel1` | Helsinki, Finland |

Set via the `location` variable. The volume is created in the same location as the server.

## Block volume

The volume (`valheim-world`) stores all world data, backups, and server config. It persists independently of the server — rebuilding or destroying the server does not touch the volume unless you run `terraform destroy`.

Default size is 10 GB, which is plenty for world saves and local backups. Increase with the `volume_size` variable in your `terraform.tfvars`.

Layout on the volume:

```
/mnt/valheim-world/
├── worlds_local/          # World save files (.db, .fwl)
├── backups/               # Automatic backup archives
└── adminlist.txt          # Server admin Steam IDs
```

## SSH access

The server is accessible via SSH as `root`:

```bash
ssh root@<server-ip>
```

By default, SSH is open to all IPs (for GitHub Actions compatibility). Restrict access by setting `allowed_ssh_ips`:

```hcl
allowed_ssh_ips = ["203.0.113.0/24"]
```

## Cloud-init

The server is bootstrapped by cloud-init on first boot. It mounts the volume, writes Docker Compose and helper scripts, and starts the container. The Hetzner `docker-ce` image reboots once after initial cloud-init — the container's `restart: always` policy handles this automatically.

Helper scripts on the server:

| Script | Purpose |
|---|---|
| `/opt/valheim/scripts/start.sh` | Start the container |
| `/opt/valheim/scripts/stop.sh` | Graceful stop (60s timeout) |
| `/opt/valheim/scripts/backup.sh` | On-demand backup to volume |

For details on how cloud-init templating works, see [Cloud-Init](cloud-init.md).
