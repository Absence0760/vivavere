# Registration settings for vivavere.com.
#
# The registration itself is bought by hand in the Route 53 console, signed in
# to the Vivavere account (README.md § Domain). Terraform does not register it:
# `aws_route53domains_domain` needs the registrant's name, address and phone
# number as configuration — which would land in this public repo — and a
# resource that owns the registration can deregister the domain on a destroy.
#
# What Terraform owns is the part that must not drift once the domain exists:
# it renews itself, it is locked against transfer, its contact details stay out
# of WHOIS, and it delegates to the hosted zone the registration created.
# Destroying this resource only removes it from state; the registration is
# untouched.

data "aws_route53_zone" "platform" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53domains_registered_domain" "platform" {
  provider = aws.us_east_1

  domain_name   = var.domain_name
  auto_renew    = true
  transfer_lock = true

  # Route 53 requires the admin, registrant and tech settings to match.
  admin_privacy      = true
  registrant_privacy = true
  tech_privacy       = true
  billing_privacy    = true

  # Sorted, because Route 53 Domains reports name servers alphabetically while
  # the hosted zone lists them in its own order; unsorted, every plan would
  # show a change.
  dynamic "name_server" {
    for_each = sort(data.aws_route53_zone.platform.name_servers)
    content {
      name = name_server.value
    }
  }
}
