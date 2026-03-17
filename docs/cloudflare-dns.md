# Cloudflare DNS

Optional. Gives your server a hostname (e.g. `valheim.example.com`) so players don't need to remember an IP address. The DNS record updates automatically on every deploy.

## Prerequisites

- A domain with nameservers pointed at Cloudflare
- A Cloudflare account (free plan works)

## Setup

### 1. Get your Zone ID

In the Cloudflare dashboard, go to your domain's **Overview** page. The Zone ID is in the right sidebar.

### 2. Create an API token

Go to **My Profile → API Tokens → Create Token**:

- Template: **Edit zone DNS**
- Zone Resources: your specific zone
- Copy the token

### 3. Add the DNS module

In your root `main.tf`, add the Cloudflare provider and DNS module:

```hcl
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "dns" {
  source = "./modules/cloudflare-dns"

  zone_id   = var.cloudflare_zone_id
  subdomain = "valheim"              # → valheim.yourdomain.com
  server_ip = module.valheim.server_ip
}
```

And add the variables to your `terraform.tfvars`:

```hcl
cloudflare_api_token = "your-cloudflare-api-token"
cloudflare_zone_id   = "your-zone-id"
```

### 4. Deploy

```bash
terraform init    # picks up the new module
terraform apply
```

The `hostname` output gives you the full FQDN.

## How it works

The `cloudflare-dns` module creates a single `cloudflare_record` resource:

- **Type**: A record
- **Content**: Server's IPv4 address (passed from the valheim module)
- **Proxied**: false (DNS only — Valheim uses UDP, which Cloudflare's proxy doesn't support)
- **TTL**: Configurable, defaults to 60 seconds

When the server is rebuilt (cloud-init change, server type change, etc.), Terraform updates the DNS record to point at the new IP automatically.

## Without Cloudflare

Don't add the `module "dns"` block, the cloudflare provider, or the cloudflare variables. Players connect using the raw IP from the `server_ip` output. You can always add DNS later without rebuilding the server — it only creates a new record.
