# Cloud-Init

Cloud-init is the single source of truth for what ends up on the server. The template at `terraform/modules/valheim-hetzner/cloud-init.yaml` is processed by Terraform's `templatefile()` function and passed as `user_data` to the Hetzner server resource.

## What it does

On first boot, cloud-init:

1. Waits for the block volume device to appear, then mounts it at `/mnt/valheim-world`
2. Adds the volume to `/etc/fstab` for persistence across reboots
3. Tunes kernel swappiness to protect game server memory
4. Writes the admin Steam ID list
5. Writes Docker Compose config, environment file, and helper scripts
6. Starts the Valheim container

## Template escaping

Since `cloud-init.yaml` is processed by `templatefile()`, every `${...}` expression is treated as a Terraform interpolation. This creates a conflict with Bash variables and Docker Compose variable substitution, which also use `${...}`.

### Rules

| Context | Syntax | Example |
|---|---|---|
| Terraform variable (from `main.tf`) | `${var}` | `${volume_device}`, `${valheim_server_name}` |
| Bash variable (in script content) | `$${var}` | `$${BACKUP_DIR}`, `$${TIMESTAMP}` |
| Docker Compose variable (in compose content) | `$${var}` | `$${SERVER_NAME}`, `$${SERVER_PASS}` |

The double-dollar `$$` tells Terraform to emit a literal `$` in the output. If you forget, Terraform will try to resolve it as a template variable and fail.

### Example

In `cloud-init.yaml`:
```yaml
# Terraform variable — resolved at plan time
- mount ${volume_device} /mnt/valheim-world

# Bash variable — double-dollar escapes to literal $
TIMESTAMP=$$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$${BACKUP_DIR}/world_$${TIMESTAMP}.tar.gz"
```

Produces on the server:
```bash
mount /dev/disk/by-id/... /mnt/valheim-world

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/world_${TIMESTAMP}.tar.gz"
```

## Triggering a rebuild

Any change to `cloud-init.yaml` (or variables it references) causes Terraform to recreate the server on the next apply. The block volume is **not** affected — world data persists across rebuilds.
