# CLAUDE.md

## Architecture

All server config (scripts, compose file, .env) is written to the server entirely through `terraform/cloud-init.yaml` using Terraform's `templatefile()`. There are no separate script files in the repo — cloud-init is the single source of truth for what ends up on the server.

## Critical: Terraform template escaping in cloud-init.yaml

`cloud-init.yaml` is processed by `templatefile()`, so any `${...}` expression is treated as a Terraform variable. Bash variables inside embedded script content must use `$${...}` to escape them (e.g. `$${BACKUP_DIR}`, `$${TIMESTAMP}`).

Terraform template variables (passed from main.tf) use normal `${...}`: `${volume_device}`, `${server_name}`, `${world_name}`, `${server_pass}`.

Docker Compose variables inside embedded compose content also use `$${...}`: `$${SERVER_NAME}`, `$${SERVER_PASS}`, etc.

## Critical: Do not write scripts to /var/lib/cloud/instance/scripts/

cloud-init's `scripts_user` module automatically executes all executable files in `/var/lib/cloud/instance/scripts/`. Writing start.sh/stop.sh there will cause them to run during cloud-init, stopping the server immediately after it starts. All scripts must be written directly to their final destinations (e.g. `/opt/valheim/scripts/`) via `write_files`.

## State

Remote state is in Terraform Cloud (org: jnsartwell, workspace: valheim). The workspace must have **Execution Mode set to Local** — otherwise TF Cloud tries to run the plan itself and won't have access to the Hetzner token.

## Block volume

The volume (`valheim-world`) persists the world save across server recreate cycles. The Hetzner docker-ce image reboots after first cloud-init run — `restart: always` on the container handles this.

## Deploy vs Destroy

- **Deploy workflow** = `terraform apply`. If cloud-init changed, Terraform recreates the server but the volume persists. World data is safe. Use this for all normal updates.
- **Destroy workflow** = `terraform destroy`. Wipes everything including the volume. World data is gone. Only use when shutting down permanently.

## GitHub Secrets required

| Secret | Purpose |
|--------|---------|
| `TF_TOKEN_APP_TERRAFORM_IO` | Terraform Cloud auth |
| `HCLOUD_TOKEN` | Hetzner API |
| `SSH_PUBLIC_KEY` | Registered with Hetzner at server creation |
| `SSH_PRIVATE_KEY` | Used by Actions workflows to SSH into server |
| `SERVER_NAME` | Valheim server browser name |
| `WORLD_NAME` | World save file name |
| `SERVER_PASS` | Server password (min 5 chars) |
| `DISCORD_WEBHOOK_URL` | Discord channel webhook for server notifications |
| `CLOUDFLARE_API_TOKEN` | Edit zone DNS permissions scoped to the domain zone |

## DNS (Cloudflare)

Terraform manages a `cloudflare_record` A resource pointing `valheim.redmist.online` at the server IP. The record must be **DNS only (proxied = false)** — Valheim uses UDP and Cloudflare's proxy only handles HTTP/HTTPS. The Zone ID is hardcoded as a variable default in `variables.tf`. The `hostname` Terraform output returns the full hostname derived from the record resource.

## Discord notifications

The lloesche/valheim-server image supports hook env vars that run shell commands on events. We use `SERVER_LISTENING_HOOK`, `PRE_STOP_HOOK`, and `POST_UPDATE_HOOK` with `curl` to post to Discord. The webhook URL flows: GitHub secret → Terraform variable → `.env` on server → Docker Compose substitution → baked into hook commands at container start.
