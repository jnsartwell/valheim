# CLAUDE.md

## Architecture

All server config (scripts, compose file, .env) is written to the server entirely through `terraform/cloud-init.yaml` using Terraform's `templatefile()`. There are no separate script files in the repo — cloud-init is the single source of truth for what ends up on the server.

## Critical: Terraform template escaping in cloud-init.yaml

`cloud-init.yaml` is processed by `templatefile()`, so any `${...}` expression is treated as a Terraform variable. Bash variables inside embedded script content must use `$${...}` to escape them (e.g. `$${BACKUP_DIR}`, `$${TIMESTAMP}`).

Terraform template variables (passed from main.tf) use normal `${...}`: `${volume_device}`, `${server_name}`, `${world_name}`, `${server_pass}`.

Docker Compose variables inside embedded compose content also use `$${...}`: `$${SERVER_NAME}`, `$${SERVER_PASS}`, etc.

## State

Remote state is in Terraform Cloud. The workspace must have **Execution Mode set to Local** — otherwise TF Cloud tries to run the plan itself and won't have access to the Hetzner token.

## Block volume

The volume (`valheim-world`) persists the world save across server destroy/recreate cycles. Do not destroy the volume independently of the server unless you intend to lose the world.
