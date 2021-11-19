module "pagerduty" {
  source = "github.com/fundingcircle/terraform-module-pagerduty?ref=v0.1.0"

  pagerduty_token        = var.pagerduty_token
  service_name           = var.service_name
  escalation_policy_name = var.escalation_policy_name

  incident_urgency_rule_type = "constant"
  urgency = "low"

  enable_honeybadger_integration = true
}
