# Contributing

Thanks for your interest in contributing! This project is open to pull requests for bug fixes, improvements, and new features.

## Development flow

1. Fork the repo and create a feature branch from `main`
2. Make your changes
3. Run `terraform validate` from the `terraform/` directory
4. Open a PR targeting `main` — Terraform Plan runs automatically for `terraform/**` changes
5. Review the plan output in the PR comment

## Project structure

```
terraform/
  main.tf                        # Root config — wires modules together
  variables.tf                   # Root variables with sensible defaults
  backend.tf                     # Terraform Cloud backend (swap for local if needed)
  modules/
    valheim-hetzner/             # Hetzner server, volume, firewall, cloud-init
    cloudflare-dns/              # Optional DNS record (separate module, easy to skip)
```

## Cloud-init gotcha

`cloud-init.yaml` is processed by Terraform's `templatefile()`. Any `${...}` is treated as a Terraform variable. Bash and Docker Compose variables must use `$${...}` to produce a literal `$` in the output. See [docs/cloud-init.md](docs/cloud-init.md) for details.

## Guidelines

- Keep PRs focused — one concern per PR
- Test with `terraform validate` at minimum; `terraform plan` if you have credentials
- Infrastructure variables (server type, location) go in the module; game-specific variables use the `valheim_` prefix
- Cloudflare is optional — changes to the valheim-hetzner module should not introduce Cloudflare dependencies
