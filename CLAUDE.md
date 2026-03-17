# CLAUDE.md

## Architecture

All server config (scripts, compose file, .env) is written to the server through `terraform/modules/valheim-hetzner/cloud-init.yaml` using Terraform's `templatefile()`. Cloud-init is the single source of truth for what ends up on the server. Scheduled backups are handled by the `lloesche/valheim-server` image's built-in support; `backup.sh` exists for on-demand backups triggered by the Actions workflow.

## Critical: Terraform template escaping in cloud-init.yaml

`cloud-init.yaml` is processed by `templatefile()`, so any `${...}` expression is treated as a Terraform variable. Bash variables inside embedded script content must use `$${...}` to escape them (e.g. `$${BACKUP_DIR}`, `$${TIMESTAMP}`).

Terraform template variables (passed from main.tf) use normal `${...}`: `${volume_device}`, `${valheim_server_name}`, `${valheim_world_name}`, `${valheim_server_pass}`.

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

## GitHub Secrets and Variables

Secrets:

| Secret | Purpose |
|--------|---------|
| `TF_TOKEN_APP_TERRAFORM_IO` | Terraform Cloud auth |
| `HCLOUD_TOKEN` | Hetzner API |
| `SSH_PUBLIC_KEY` | Registered with Hetzner at server creation |
| `SSH_PRIVATE_KEY` | Used by Actions workflows to SSH into server |
| `SERVER_PASS` | Server password (min 5 chars) |
| `DISCORD_WEBHOOK_URL` | Discord channel webhook for server notifications |
| `CLOUDFLARE_API_TOKEN` | Edit zone DNS permissions scoped to the domain zone (optional) |

Variables:

| Variable | Purpose |
|----------|---------|
| `SERVER_NAME` | Valheim server browser name |
| `WORLD_NAME` | World save file name |
| `SERVER_HOST` | Server hostname or IP used by operational workflows (e.g. `valheim.example.com`) |
| `CLOUDFLARE_ZONE_ID` | Cloudflare zone ID (leave empty to skip DNS) |
| `VALHEIM_ADMIN_IDS` | Steam 64-bit IDs as JSON array (e.g. `["765..."]`) |

## DNS (Cloudflare) — optional

Cloudflare DNS is a separate module (`modules/cloudflare-dns`). The valheim module is pure Hetzner with no Cloudflare dependency. Root `main.tf` calls both modules — users who don't want DNS remove the `module "dns"` block, the cloudflare provider, and the related variables. The Zone ID is passed via the `CLOUDFLARE_ZONE_ID` GitHub Actions variable.

## Backups

Automatic server-side backups are handled by the `lloesche/valheim-server` image via `BACKUPS=true`. Runs every 6 hours (`BACKUPS_CRON`), stores archives in `/config/backups` on the world volume, and retains 7 days (`BACKUPS_MAX_AGE`).

`backup.sh` on the server exists for on-demand backups triggered by the Backup: Snapshot workflow. It tars `worlds_local/` directly — no server process signaling needed since the image handles save flushing internally.

## World Import

External world saves can be imported via GitHub Releases. The import workflow (`import-world.yml`) accepts a release tag, downloads the `.tar.gz` asset, validates it contains `.db` and `.fwl` files, and extracts them to the server. If the source world name differs from the configured `WORLD_NAME`, files are automatically renamed. Texture caches are cleared on import since they're world-specific.

Archive format for import: a flat tarball containing `<WorldName>.db` and `<WorldName>.fwl` at root (no directory wrapper).

## Operational workflows and SSH

Backup, restore, import, and restart workflows connect to the server via SSH using the `SERVER_HOST` variable (hostname or IP). They do not require Terraform — only deploy, plan, manual deploy, and destroy workflows use Terraform. This keeps operational workflows fast and avoids unnecessary Terraform Cloud dependencies.

## Discord notifications

The lloesche/valheim-server image supports hook env vars that run shell commands on events. We use `POST_SERVER_LISTENING_HOOK` and `PRE_SERVER_SHUTDOWN_HOOK` with `curl` to post to Discord. The webhook URL flows: GitHub secret → Terraform variable → `.env` on server → Docker Compose substitution → baked into hook commands at container start.
