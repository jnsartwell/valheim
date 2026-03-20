# Backups

World data is protected by on-demand server-side backups and GitHub Actions workflows for offsite copies stored as artifacts.

## On-demand backup script

A `backup.sh` script on the server creates an immediate backup of the active world:

```bash
ssh root@<server> /opt/valheim/scripts/backup.sh
```

This reads `WORLD_NAME` from `.env` and tars only that world's files (`<name>.db`, `<name>.fwl`) to `/opt/valheim/data/backups/`.

## GitHub Actions workflows

If you use the included GitHub Actions workflows, you get offsite backup and restore capabilities. See [GitHub Actions](github-actions.md) for full setup.

### Backup: Snapshot

Triggers `backup.sh` on the server, downloads the archive as a GitHub Actions artifact (90-day retention), then deletes the on-server file. Runs on manual trigger and daily at 6am UTC.

Artifact names follow the pattern `{prefix}-{short_sha}-{timestamp}` (e.g. `snapshot-abc1234-20260316-1253`). The short SHA ties the backup to the exact commit that triggered it.

### Backup: Restore

Restores a named GitHub artifact to the server. If you provide a wrong name, the workflow lists available artifacts.

## Important: server recreates

Since world data lives on the server's local disk (not a persistent volume), a server recreate (triggered by any Terraform change to the server resource) wipes game data. The deploy workflow takes a pre-deploy backup artifact automatically. After a recreate, use the Restore workflow to bring the world back.
