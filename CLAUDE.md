# CLAUDE.md

## Project summary

IaC repo for a self-hosted Valheim dedicated server on Hetzner Cloud. Terraform provisions the server; cloud-init configures everything; GitHub Actions handles CI/CD and operations. The game server runs via the `lloesche/valheim-server` Docker image.

## Tech stack

- **Provisioning:** Terraform (>= 1.9) with Hetzner (`hcloud`) and Cloudflare providers
- **Server config:** Cloud-init (YAML) writing Docker Compose, `.env`, and shell scripts
- **Container:** `lloesche/valheim-server` (Docker Compose, `restart: always`)
- **CI/CD:** GitHub Actions — plan on PR, apply on merge, manual operational workflows
- **State:** Terraform Cloud (org: jnsartwell, workspace: valheim, execution mode: **Local**)
- **DNS:** Cloudflare (optional separate module)
- **Notifications:** Discord webhooks via container hook env vars

## Architecture

All server config (scripts, compose file, .env) is written through `terraform/modules/valheim-hetzner/cloud-init.yaml` using Terraform's `templatefile()`. Cloud-init is the single source of truth for what ends up on the server.

Two Terraform modules:
- `modules/valheim-hetzner` — server, volume, firewall, SSH key, cloud-init
- `modules/cloudflare-dns` — optional A record; no coupling to the valheim module

## Critical: Terraform template escaping in cloud-init.yaml

`cloud-init.yaml` is processed by `templatefile()`, so `${...}` is a Terraform variable. Bash variables must use `$${...}` to escape (e.g. `$${BACKUP_DIR}`, `$${TIMESTAMP}`). Docker Compose substitution vars also use `$${...}`: `$${SERVER_NAME}`, `$${SERVER_PASS}`, etc.

Terraform template variables use normal `${...}`: `${volume_device}`, `${valheim_server_name}`, `${valheim_world_name}`, `${valheim_server_pass}`.

## Block volume

The volume (`valheim-world`) persists world saves across server recreate cycles. Mounted at `/mnt/valheim-world`. The Hetzner docker-ce image reboots after first cloud-init run — `restart: always` on the container handles this.

## Development flow

All changes go through feature branches and PRs — never commit directly to `main`.

- PR opened → **Terraform Plan** runs (for `terraform/**` changes)
- Merge to `main` → **Terraform Apply** runs
- **Manual Deploy** → `workflow_dispatch`, gated by `infra` environment approval

Repository admins can self-merge without reviewer approval.

## Deploy vs Destroy

- **Deploy** (merge to main) = `terraform apply`. Volume persists. World data is safe.
- **Manual Deploy** (workflow_dispatch) = force deploy, gated by `infra` approval.
- **Destroy** = `terraform destroy`. Wipes everything including volume. Permanent shutdown only.

## GitHub Secrets and Variables

Full tables with per-workflow usage are in `docs/github-actions.md`. Key secrets: `HCLOUD_TOKEN`, `TF_TOKEN_APP_TERRAFORM_IO`, `SSH_PRIVATE_KEY`, `SERVER_PASS`, `DISCORD_WEBHOOK_URL`, `CLOUDFLARE_API_TOKEN`. Key variables: `SERVER_NAME`, `WORLD_NAME`, `SERVER_HOST`, `CLOUDFLARE_ZONE_ID`, `VALHEIM_ADMIN_IDS`.

## Backups

Automatic backups via `lloesche/valheim-server` (`BACKUPS=true`, every 6 hours, 7-day retention). On-demand backups via `backup.sh` triggered by the Backup: Snapshot workflow — tars `worlds_local/` directly.

## World Switching

Multiple world saves coexist on the volume under `/mnt/valheim-world/worlds_local/`. Terraform is the source of truth for which world is active via the `WORLD_NAME` variable.

- **Upload a new world:** `./scripts/upload-world.sh --db <path> --fwl <path> --host <hostname>` (SCPs files directly to server volume)
- **Switch worlds:** Change the `WORLD_NAME` GitHub variable and deploy (PR or Manual Deploy). Server picks up the new name from `.env` on container restart.

## Operational workflows and SSH

Backup, restore, restart, and status workflows connect via SSH using `SERVER_HOST`. They do not use Terraform. Only deploy, plan, manual deploy, and destroy workflows use Terraform.

## Discord notifications

Hook env vars (`POST_SERVER_LISTENING_HOOK`, `PRE_SERVER_SHUTDOWN_HOOK`) run `curl` to post to Discord. Flow: GitHub secret → Terraform variable → `.env` → Docker Compose substitution → hook commands at container start.

## Code style and conventions

- **Commit messages:** Viking/Norse-themed language (see git log for examples)
- **Branching:** Always pull latest `main` before creating feature branches
- **Terraform:** Provider versions pinned with `~>`. Variables have sensible defaults where possible.
- **Shell scripts:** `set -euo pipefail`, double-quote variables, validate inputs before acting

## TODOs

None currently tracked. The world-switching feature (replacing the old import-world workflow) is implemented but not yet committed.
