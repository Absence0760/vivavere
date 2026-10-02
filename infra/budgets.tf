# Account-wide monthly spend ceiling. The Vivavere account holds nothing but
# this project, so account-wide is the right scope. Three notifications, all to
# var.budget_alert_emails: 50 % and 100 % of actual spend, and 100 % of
# forecast — the forecast is the one that catches a runaway early.
#
# If an apply is refused with "ask the payer account to enable budgets", turn
# on "IAM user and role access to billing information" in the account's root
# settings rather than removing the budget.

resource "aws_budgets_budget" "monthly" {
  name         = "${var.project}-${var.environment}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_limit_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.budget_alert_emails
  }
}
