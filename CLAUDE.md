# CLAUDE.md

## Project summary

IaC repo for a self-hosted Valheim dedicated server on Hetzner Cloud. Terraform provisions the server; cloud-init + file provisioner configures everything; GitHub Actions handles CI/CD and operations. The game server runs via the `lloesche/valheim-server` Docker image.

## Tech stack

- **Provisioning:** Terraform (>= 1.9) with Hetzner (`hcloud`) and Cloudflare providers
- **Server config:** Cloud-init (YAML) for `.env` and kernel tuning; file provisioner for scripts and compose
- **Container:** `lloesche/valheim-server` (Docker Compose, `restart: always`)
- **CI/CD:** GitHub Actions — plan on PR, apply on merge, manual operational workflows
- **State:** Terraform Cloud (org: jnsartwell, workspace: valheim, execution mode: **Local**)
- **DNS:** Cloudflare (optional separate module)
- **Notifications:** Discord webhooks via container hook env vars

## Architecture

Server config is split between cloud-init (`.env`, kernel tuning, admin list) and the file provisioner (scripts + compose from `terraform/server-scripts/`). Cloud-init runs first; the provisioner waits for it, copies files, then starts the container.

Two Terraform modules:
- `modules/valheim-hetzner` — server, firewall, SSH key, cloud-init, file provisioner
- `modules/cloudflare-dns` — optional A record; no coupling to the valheim module

## Critical: Terraform template escaping in cloud-init.yaml

`cloud-init.yaml` is processed by `templatefile()`, so `${...}` is a Terraform variable. Bash variables must use `$${...}` to escape.

Terraform template variables use normal `${...}`: `${valheim_server_name}`, `${valheim_world_name}`, `${valheim_server_pass}`.

Note: Scripts in `terraform/server-scripts/` are NOT processed by `templatefile()` — they use normal `${VAR}` syntax (read from `.env` at runtime).

## Data storage

World data lives on the server's local disk at `/opt/valheim/data`. No persistent block volume — server recreates wipe game data. The deploy workflow takes a pre-deploy backup artifact automatically; use the Restore workflow to recover after a recreate.

## Development flow

All changes go through feature branches and PRs — never commit directly to `main`.

- PR opened → **Terraform Plan** runs (for `terraform/**` changes)
- Merge to `main` → **Terraform Apply** runs
- **Manual Deploy** → `workflow_dispatch`, gated by `infra` environment approval

Repository admins can self-merge without reviewer approval.

## Deploy vs Destroy

- **Deploy** (merge to main) = `terraform apply`. Pre-deploy backup taken automatically.
- **Manual Deploy** (workflow_dispatch) = force deploy, gated by `infra` approval.
- **Destroy** = `terraform destroy`. Wipes everything. Permanent shutdown only.

## GitHub Secrets and Variables

Full tables with per-workflow usage are in `docs/github-actions.md`. Key secrets: `HCLOUD_TOKEN`, `TF_TOKEN_APP_TERRAFORM_IO`, `SSH_PRIVATE_KEY`, `SERVER_PASS`, `DISCORD_WEBHOOK_URL`, `CLOUDFLARE_API_TOKEN`. Key variables: `SERVER_NAME`, `SERVER_HOST`, `CLOUDFLARE_ZONE_ID`, `VALHEIM_ADMIN_IDS`.

## Backups

On-demand backups via `backup.sh` — backs up only the active world (reads `WORLD_NAME` from `.env`). Triggered by the Backup: Snapshot workflow, which downloads the archive as a GitHub artifact and cleans up the on-server file.

## World Switching

Multiple world saves coexist under `/opt/valheim/data/worlds_local/`. Terraform is the source of truth for which world is active via `valheim_world_name` in `terraform/main.tf`.

- **Upload a new world:** `./scripts/upload-world.sh --db <path> --fwl <path> --host <hostname>` (SCPs files directly to server)
- **Switch worlds:** Change `valheim_world_name` in `terraform/main.tf` and deploy via PR. Server picks up the new name from `.env` on container restart.

## Operational workflows and SSH

Backup, restore, restart, and status workflows connect via SSH using `SERVER_HOST`. They do not use Terraform. Only deploy, plan, manual deploy, and destroy workflows use Terraform.

## Discord notifications

Hook env vars (`POST_SERVER_LISTENING_HOOK`, `PRE_SERVER_SHUTDOWN_HOOK`) run `curl` to post to Discord. Flow: GitHub secret → Terraform variable → `.env` → Docker Compose substitution → hook commands at container start.

## Code style and conventions

- **Commit messages:** Viking/Norse-themed language (see git log for examples)
- **Branching:** Always pull latest `main` before creating feature branches. Branches that only switch the active world use the `world-switch/` prefix (e.g. `world-switch/panthera`).
- **Terraform:** Provider versions pinned with `~>`. Variables have sensible defaults where possible.
- **Shell scripts:** `set -euo pipefail`, double-quote variables, validate inputs before acting

## TODOs

None currently tracked.
