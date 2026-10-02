# Mail DNS for vivavere.com: mailboxes (contact@ and any aliases) hosted on
# Migadu, in the estate's existing Migadu account alongside jaredhoward.com,
# threkir.com and feohledger.com.
#
# The records live on the apex: MX, the SPF + ownership TXT, three DKIM CNAMEs,
# the mail-client autoconfig hints, and DMARC. Migadu's targets are the same for
# every domain; the only account-specific value is the ownership token
# (var.migadu_verification_token, in the operator's tfvars).
#
# Migadu is the only sender today, so the SPF authorizes it alone and fails
# hard. If app mail (SES, Resend) is ever added, give it its own envelope
# subdomain the way feohledger does with `send.` rather than widening this SPF.

locals {
  # Route 53 keys a record set by name and type, so the SPF and Migadu's
  # ownership token share the one apex TXT record. `try` drops the token while
  # it is still null.
  apex_txt = compact([
    "v=spf1 include:spf.migadu.com -all",
    try("hosted-email-verify=${var.migadu_verification_token}", ""),
  ])

  dmarc = join(" ", compact([
    "v=DMARC1;",
    "p=${var.dmarc_policy};",
    try("rua=mailto:${var.dmarc_report_email};", ""),
  ]))

  migadu_srv = {
    "_autodiscover._tcp" = "0 1 443 autoconfig.migadu.com."
    "_submissions._tcp"  = "0 1 465 smtp.migadu.com."
    "_imaps._tcp"        = "0 1 993 imap.migadu.com."
  }
}

resource "aws_route53_record" "migadu_mx" {
  zone_id = data.aws_route53_zone.platform.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 300
  records = ["10 aspmx1.migadu.com", "20 aspmx2.migadu.com"]
}

resource "aws_route53_record" "apex_txt" {
  zone_id = data.aws_route53_zone.platform.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 300
  records = local.apex_txt
}

resource "aws_route53_record" "migadu_dkim" {
  for_each = toset(["key1", "key2", "key3"])

  zone_id = data.aws_route53_zone.platform.zone_id
  name    = "${each.key}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["${each.key}.${var.domain_name}._domainkey.migadu.com."]
}

resource "aws_route53_record" "migadu_autoconfig" {
  zone_id = data.aws_route53_zone.platform.zone_id
  name    = "autoconfig.${var.domain_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["autoconfig.migadu.com."]
}

# Mail-client discovery hints (Thunderbird, Apple Mail, phones). Delivery does
# not need them; they only save setting up a mailbox by hand.
resource "aws_route53_record" "migadu_srv" {
  for_each = local.migadu_srv

  zone_id = data.aws_route53_zone.platform.zone_id
  name    = "${each.key}.${var.domain_name}"
  type    = "SRV"
  ttl     = 300
  records = [each.value]
}

resource "aws_route53_record" "dmarc" {
  zone_id = data.aws_route53_zone.platform.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 300
  records = [local.dmarc]
}
