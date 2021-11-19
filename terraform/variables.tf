
variable "escalation_policy_name" {
  default = "Global Platform Escalation Policy"
}

variable "service_name" {
  default = "shipment_tracker"
}

variable "aws_account_id" {
  type    = string
  default = "058180101585" # UAT
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "environment" {
  type    = string
  default = "uat"
}

variable "legacy_vpc_security_group_id" {
  type    = string
  default = "sg-6b57e40f" # UAT
}

