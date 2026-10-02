output "zone_id" {
  description = "Route 53 hosted zone ID of vivavere.com, for records a future website or app stack adds."
  value       = data.aws_route53_zone.platform.zone_id
}

output "name_servers" {
  description = "The zone's name servers — what the registration delegates to."
  value       = data.aws_route53_zone.platform.name_servers
}
