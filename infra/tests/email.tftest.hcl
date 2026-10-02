# Plan-only tests against mocked AWS providers — no credentials, no state.
# They pin the mail records and input guards, which `terraform validate`
# cannot see.

mock_provider "aws" {}

mock_provider "aws" {
  alias = "us_east_1"
}

override_data {
  target = data.aws_route53_zone.platform
  values = {
    zone_id      = "Z0000000000000000000"
    name_servers = ["ns-2.example.org", "ns-1.example.net"]
  }
}

variables {
  budget_alert_emails = ["ops@vivavere.com"]
}

run "mail_records_without_token" {
  command = plan

  assert {
    condition     = aws_route53_record.apex_txt.records == toset(["v=spf1 include:spf.migadu.com -all"])
    error_message = "Without a token the apex TXT must carry only the SPF."
  }

  assert {
    condition     = aws_route53_record.migadu_mx.records == toset(["10 aspmx1.migadu.com", "20 aspmx2.migadu.com"])
    error_message = "MX must point at both Migadu exchangers."
  }

  assert {
    condition     = aws_route53_record.migadu_dkim["key1"].records == toset(["key1.vivavere.com._domainkey.migadu.com."])
    error_message = "DKIM CNAMEs must target Migadu's per-domain keys."
  }

  assert {
    condition     = aws_route53_record.dmarc.records == toset(["v=DMARC1; p=none;"])
    error_message = "DMARC without a report address is the bare policy."
  }

  assert {
    condition     = [for ns in aws_route53domains_registered_domain.platform.name_server : ns.name] == ["ns-1.example.net", "ns-2.example.org"]
    error_message = "Registration name servers must be the zone's, sorted."
  }
}

run "mail_records_with_token" {
  command = plan

  variables {
    migadu_verification_token = "abc123xy"
    dmarc_report_email        = "contact@vivavere.com"
  }

  assert {
    condition     = aws_route53_record.apex_txt.records == toset(["v=spf1 include:spf.migadu.com -all", "hosted-email-verify=abc123xy"])
    error_message = "The token must join the SPF in the one apex TXT record."
  }

  assert {
    condition     = aws_route53_record.dmarc.records == toset(["v=DMARC1; p=none; rua=mailto:contact@vivavere.com;"])
    error_message = "DMARC must carry the report address."
  }
}

run "rejects_full_verify_string" {
  command = plan

  variables {
    migadu_verification_token = "hosted-email-verify=abc123xy"
  }

  expect_failures = [var.migadu_verification_token]
}

run "rejects_offdomain_dmarc_address" {
  command = plan

  variables {
    dmarc_report_email = "someone@gmail.com"
  }

  expect_failures = [var.dmarc_report_email]
}

run "rejects_placeholder_alert_email" {
  command = plan

  variables {
    budget_alert_emails = ["alerts@example.com"]
  }

  expect_failures = [var.budget_alert_emails]
}
