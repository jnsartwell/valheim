# Cloud-Init

Cloud-init handles initial server configuration on first boot. The template at `terraform/modules/valheim-hetzner/cloud-init.yaml` is processed by Terraform's `templatefile()` function and passed as `user_data` to the Hetzner server resource.

## What it does

On first boot, cloud-init:

1. Tunes kernel swappiness to protect game server memory
2. Creates the data directory at `/opt/valheim/data`
3. Writes the admin Steam ID list
4. Writes the Docker environment file (`.env`)

Scripts, compose file, and container startup are handled separately by the Terraform file provisioner (see [Hetzner](hetzner.md)).

## Template escaping

Since `cloud-init.yaml` is processed by `templatefile()`, every `${...}` expression is treated as a Terraform interpolation.

### Rules

| Context | Syntax | Example |
|---|---|---|
| Terraform variable (from `main.tf`) | `${var}` | `${valheim_server_name}`, `${valheim_world_name}` |
| Bash variable (in script content) | `$${var}` | `$${BACKUP_DIR}`, `$${TIMESTAMP}` |

The double-dollar `$$` tells Terraform to emit a literal `$` in the output. If you forget, Terraform will try to resolve it as a template variable and fail.

### Example

In `cloud-init.yaml`:
```yaml
# Terraform variable — resolved at plan time
SERVER_NAME=${valheim_server_name}
```

Produces on the server:
```bash
SERVER_NAME=MyValheimServer
```

## Triggering a rebuild

Any change to `cloud-init.yaml` (or variables it references) causes Terraform to recreate the server on the next apply. World data is on local disk, so a rebuild wipes game data — the deploy workflow takes a pre-deploy backup artifact automatically.
