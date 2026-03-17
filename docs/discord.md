# Discord Notifications

Optional. The server posts to a Discord channel when it comes online or goes offline.

| Event | Message |
|---|---|
| Server ready | `<ServerName> is online! Connect now.` |
| Server stopping | `<ServerName> is going offline.` |

## Setup

### 1. Create a webhook

In Discord: **Server Settings → Integrations → Webhooks → New Webhook**

- Choose the channel for notifications
- Copy the webhook URL

### 2. Configure Terraform

Add to your `terraform.tfvars`:

```hcl
discord_webhook_url = "https://discord.com/api/webhooks/..."
```

### 3. Deploy

```bash
terraform apply
```

That's it. The webhook URL flows into the container's environment and the [lloesche/valheim-server](https://github.com/lloesche/valheim-server-docker) image handles the rest via hook environment variables.

## How it works

The Valheim Docker image supports `POST_SERVER_LISTENING_HOOK` and `PRE_SERVER_SHUTDOWN_HOOK` — shell commands that run on server events. These are set to `curl` commands that POST to your Discord webhook.

If the webhook URL is empty, the hooks silently skip (guarded by `[ -n "$DISCORD_WEBHOOK_URL" ]`).

## Without Discord

If you don't set `discord_webhook_url`, no notifications are sent. The hook commands are still present in the container config but no-op when the URL is empty. You can add a webhook later without rebuilding the server — just update the variable and redeploy.
