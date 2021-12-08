
variable "escalation_policy_name" {
  default = "Global Platform Escalation Policy"
}

variable "service_name" {
  default = "shipment-tracker"
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

variable "aurora_acus_min" {
  type    = number
  default = 2
}

variable "aurora_acus_max" {
  type    = number
  default = 2
}
