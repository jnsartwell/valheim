# Backups

World data is protected by multiple backup layers: automatic in-container backups, on-demand server-side backups, and GitHub Actions workflows for offsite copies.

## Automatic backups (built-in)

The [lloesche/valheim-server](https://github.com/lloesche/valheim-server-docker) image handles automatic backups internally:

- **Schedule**: Every 6 hours (`BACKUPS_CRON`)
- **Location**: `/mnt/valheim-world/backups/` (on the persistent volume)
- **Retention**: 7 days (`BACKUPS_MAX_AGE`)
- **Save flushing**: Handled by the image — no process signaling needed

These require no setup beyond the default configuration.

## On-demand backup script

A `backup.sh` script on the server creates an immediate backup:

```bash
ssh root@<server> /opt/valheim/scripts/backup.sh
```

This tars `worlds_local/` to the volume's backup directory with a timestamp and prunes backups older than 7 days.

## GitHub Actions workflows

If you use the included GitHub Actions workflows, you get offsite backup and restore capabilities. See [GitHub Actions](github-actions.md) for full setup.

### Backup: Snapshot

Triggers `backup.sh` on the server and downloads the archive as a GitHub Actions artifact (90-day retention). Runs on manual trigger and daily at 6am UTC.

Artifact names include the world name and timestamp: `valheim-world-MyWorld-20260316-1253`.

### Backup: Restore

Restores a named GitHub artifact to the server. If you provide a wrong name, the workflow lists available artifacts.

Note: Restoring a backup overwrites matching world files but preserves other worlds on the volume (multi-world safe).
