variable "pagerduty_token" {}

variable "escalation_policy_name" {
  default = "Global Platform Escalation Policy"
}

variable "service_name" {
  default = "shipment_tracker"
}
