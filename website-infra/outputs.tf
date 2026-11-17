output "name_servers" {
  description = "Set these as custom nameservers at the domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "site_url" {
  value = "https://${var.domain}"
}

output "cloudfront_domain" {
  value = try(aws_cloudfront_distribution.site.domain_name, null)
}

output "bucket" {
  value = aws_s3_bucket.site.bucket
}
