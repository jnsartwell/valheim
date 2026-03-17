output "hostname" {
  description = "Fully qualified domain name of the DNS record"
  value       = cloudflare_record.server.hostname
}
