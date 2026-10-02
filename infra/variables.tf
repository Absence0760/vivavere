variable "aws_region" {
  description = "Primary AWS region for this module."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project slug used for resource naming + default_tags."
  type        = string
  default     = "vivavere"
}

variable "environment" {
  description = "Deployment environment. Part of resource names and tags."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "The registered apex domain. It must be registered through Route 53 in this account, which creates the public hosted zone of the same name that domain.tf and email.tf look up (README.md § Domain)."
  type        = string
  default     = "vivavere.com"

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?\\.[a-z]{2,}$", var.domain_name))
    error_message = "domain_name must be a registered apex such as vivavere.com, not a subdomain: domain.tf manages the domain's registration, and only the apex has one."
  }
}

variable "monthly_budget_limit_usd" {
  description = "Monthly AWS spend ceiling (USD) for the account-wide budget. The account holds one hosted zone (0.50 USD/month) and a state bucket; the domain's yearly renewal is billed separately by Route 53 Domains and lands as one spike, so 10 leaves room for it without hiding a runaway."
  type        = number
  default     = 10

  validation {
    condition     = var.monthly_budget_limit_usd > 0
    error_message = "monthly_budget_limit_usd must be positive — a zero budget alerts on the first cent and trains everyone to ignore it."
  }
}

variable "budget_alert_emails" {
  description = "Addresses that receive every budget notification. No default: this repo is public, so the real address lives only in the operator's tfvars (canonical copy in the private infra-secrets repo)."
  type        = list(string)

  validation {
    condition     = length(var.budget_alert_emails) > 0
    error_message = "Provide at least one address in budget_alert_emails — a budget with no subscribers alerts no one."
  }

  validation {
    condition     = alltrue([for e in var.budget_alert_emails : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", e))])
    error_message = "Every entry in budget_alert_emails must be an email address."
  }

  validation {
    condition     = alltrue([for e in var.budget_alert_emails : !can(regex("(?i)@example\\.(com|org|net)$", e))])
    error_message = "budget_alert_emails still holds the example placeholder — replace it with a real address."
  }
}

variable "migadu_verification_token" {
  description = "Migadu's ownership token for the domain: the value after `hosted-email-verify=` at admin.migadu.com → Domains → <domain> → DNS Configuration. Not secret (it is published in DNS), but account-specific, so it lives in the operator's tfvars. Null until the domain is added in Migadu; every other mail record is created anyway."
  type        = string
  default     = null

  validation {
    condition     = var.migadu_verification_token == null || can(regex("^[A-Za-z0-9]+$", var.migadu_verification_token))
    error_message = "migadu_verification_token is the bare token, such as p8dxwnab, not the whole hosted-email-verify=... string."
  }
}

variable "dmarc_policy" {
  description = "What receivers do with mail that fails DMARC. Starts at `none` (monitor only); raise to `quarantine`, then `reject`, once aggregate reports show Migadu mail aligning."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "dmarc_policy must be none, quarantine or reject."
  }
}

variable "dmarc_report_email" {
  description = "Mailbox that receives DMARC aggregate reports (rua), such as contact@<domain> on Migadu. Published in DNS. Must be on the domain itself: receivers drop reports addressed to another domain that has not authorized them. Null publishes the policy with no reporting address."
  type        = string
  default     = null

  validation {
    condition     = var.dmarc_report_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.dmarc_report_email))
    error_message = "dmarc_report_email must be an email address."
  }

  validation {
    condition     = var.dmarc_report_email == null || can(regex("@${replace(lower(var.domain_name), ".", "\\.")}$", lower(var.dmarc_report_email)))
    error_message = "dmarc_report_email must be a mailbox on the domain itself; receivers drop reports addressed to another domain that has not authorized them."
  }
}
