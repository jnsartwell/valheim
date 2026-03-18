# GitHub Actions

Optional CI/CD workflows for managing the server through pull requests and manual triggers. You can use the Terraform module without any of this — these workflows are for teams that want automated, PR-gated deployments and operational tooling.

## How it works

1. Create a branch and make `terraform/` changes
2. Open a PR targeting `main` — **Terraform Plan** runs automatically
3. Review the plan diff in the PR's job summary
4. Merge — **Deploy** runs automatically and applies the plan

For emergencies, **Manual Deploy** is available via `workflow_dispatch` with environment approval.

## Workflows

### Infrastructure

| Workflow | Trigger | What it does |
|---|---|---|
| **Terraform Plan** | PR targeting `main` | Runs `terraform plan`, posts diff to the job summary |
| **Deploy Valheim Server** | Merge to `main` | Runs `terraform apply`. Volume and world data persist. |
| **Manual Deploy Valheim Server** | Manual | Force deploy outside PR flow. Requires `infra` environment approval. |
| **Destroy Valheim Server** | Manual | `terraform destroy` — wipes everything including volume. Type `DESTROY` to confirm. |

### Operations

| Workflow | Trigger | What it does |
|---|---|---|
| **Power Off Hetzner Server** | Manual | Graceful container stop, then Hetzner power off. Billing continues. |
| **Power On Hetzner Server** | Manual | Powers server on. Container starts automatically. |
| **Restart Valheim Container** | Manual | Restarts the Docker container without touching the server. |
| **Server Status** | Manual | Shows Hetzner server state, IP, container status, memory. |

### Backups

| Workflow | Trigger | What it does |
|---|---|---|
| **Backup: Snapshot** | Manual / daily 6am UTC | Triggers backup on server, downloads as artifact (90-day retention). |
| **Backup: Restore** | Manual | Restores a named artifact to the server. Lists available on failure. |

## Setup

### 1. GitHub Environment

Create an `infra` environment for deployment gates:

**Repo → Settings → Environments → New environment** → name it `infra`

Under **Deployment protection rules**, enable **Required reviewers** and add yourself. This gates Manual Deploy behind approval.

### 2. Secrets

**Repo → Settings → Secrets and variables → Actions → Secrets**

| Secret | Used by | Purpose |
|---|---|---|
| `TF_TOKEN_APP_TERRAFORM_IO` | Plan, Deploy, Destroy | Terraform Cloud authentication |
| `HCLOUD_TOKEN` | Plan, Deploy, Destroy, Power On/Off, Status | Hetzner API |
| `SSH_PUBLIC_KEY` | Plan, Deploy | Registered with Hetzner at server creation |
| `SSH_PRIVATE_KEY` | Deploy, Backup, Restore, Restart, Status, Power Off | SSH into server for operational tasks |
| `SERVER_PASS` | Plan, Deploy | Valheim server password |
| `CLOUDFLARE_API_TOKEN` | Plan, Deploy | Cloudflare DNS (only if using Cloudflare) |
| `DISCORD_WEBHOOK_URL` | Deploy | Discord notifications (only if using Discord) |

### 3. Variables

**Repo → Settings → Secrets and variables → Actions → Variables**

| Variable | Used by | Purpose |
|---|---|---|
| `SERVER_NAME` | Plan, Deploy | Server name in the game browser |
| `WORLD_NAME` | Plan, Deploy, Backup | World save file name |
| `SERVER_HOST` | Backup, Restore, Restart, Status, Power Off | Hostname or IP for SSH access |
| `CLOUDFLARE_ZONE_ID` | Plan, Deploy | Cloudflare zone ID (leave empty to skip DNS) |
| `VALHEIM_ADMIN_IDS` | Plan, Deploy | Steam 64-bit IDs as JSON array (e.g. `["765..."]`) |

### 4. Terraform Cloud

The workflows use Terraform Cloud for remote state:

1. Create a free account at [app.terraform.io](https://app.terraform.io)
2. Create an organization and workspace named `valheim`
3. Set **Execution Mode** to **Local** (required — otherwise TF Cloud tries to run the plan itself)
4. Create a user API token → `TF_TOKEN_APP_TERRAFORM_IO` secret

## Operational workflows and SSH

Backup, restore, restart, and status workflows connect directly to the server via SSH. They don't use Terraform — only plan, deploy, and destroy workflows need Terraform Cloud. This keeps operational workflows fast.
