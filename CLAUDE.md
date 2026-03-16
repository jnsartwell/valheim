# CLAUDE.md

## Architecture

All server config (scripts, compose file, .env) is written to the server through `terraform/modules/valheim/cloud-init.yaml` using Terraform's `templatefile()`. Cloud-init is the single source of truth for what ends up on the server. Scheduled backups are handled by the `lloesche/valheim-server` image's built-in support; `backup.sh` exists for on-demand backups triggered by the Actions workflow.

## Critical: Terraform template escaping in cloud-init.yaml

`cloud-init.yaml` is processed by `templatefile()`, so any `${...}` expression is treated as a Terraform variable. Bash variables inside embedded script content must use `$${...}` to escape them (e.g. `$${BACKUP_DIR}`, `$${TIMESTAMP}`).

Terraform template variables (passed from main.tf) use normal `${...}`: `${volume_device}`, `${server_name}`, `${world_name}`, `${server_pass}`.

Docker Compose variables inside embedded compose content also use `$${...}`: `$${SERVER_NAME}`, `$${SERVER_PASS}`, etc.

## State

Remote state is in Terraform Cloud (org: jnsartwell, workspace: valheim). The workspace must have **Execution Mode set to Local** — otherwise TF Cloud tries to run the plan itself and won't have access to the Hetzner token.

## Block volume

The volume (`valheim-world`) persists the world save across server recreate cycles. The Hetzner docker-ce image reboots after first cloud-init run — `restart: always` on the container handles this.

## Development flow

All changes must go through a feature branch and pull request — never commit directly to `main`.

```bash
git checkout -b feat/your-change
# make changes
git add .
git commit -m "..."
git push -u origin feat/your-change
# open PR on GitHub
```

Opening a PR triggers **Terraform Plan** automatically (for `terraform/**` changes). Merging to `main` triggers **Terraform Apply**. For emergencies, **Manual Deploy** is available via `workflow_dispatch` and requires `infra` environment approval.

Repository admins are on the bypass list and can self-merge without a reviewer approval.

## Deploy vs Destroy

- **Deploy** (merge to main) = `terraform apply`. If cloud-init changed, Terraform recreates the server but the volume persists. World data is safe.
- **Manual Deploy** (workflow_dispatch) = force deploy outside the PR flow, gated by `infra` environment approval.
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

## Backups

Handled by the `lloesche/valheim-server` image via `BACKUPS=true`. Runs every 6 hours (`BACKUPS_CRON`), stores archives in `/config/backups` on the world volume, and retains 7 days (`BACKUPS_MAX_AGE`). No host-side scripts or systemd timers needed.

## Discord notifications

The lloesche/valheim-server image supports hook env vars that run shell commands on events. We use `POST_SERVER_LISTENING_HOOK` and `PRE_SERVER_SHUTDOWN_HOOK` with `curl` to post to Discord. The webhook URL flows: GitHub secret → Terraform variable → `.env` on server → Docker Compose substitution → baked into hook commands at container start.
