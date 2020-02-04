module "pagerduty" {
  source = "github.com/fundingcircle/terraform-module-pagerduty?ref=v0.0.6"

  pagerduty_token        = "${var.pagerduty_token}"
  service_name           = "${var.service_name}"
  escalation_policy_name = "${var.escalation_policy_name}"

  enable_honeybadger_integration = true
}
