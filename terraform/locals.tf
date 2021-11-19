locals {
  role = {
    drone = format("arn:aws:iam::%s:role/automation-drone", var.aws_account_id)
    admin = format("arn:aws:iam::%s:role/Admin", var.aws_account_id)
  }
  environment = {
    name = var.environment == "uat" ? "euat" : var.environment
    is = {
      production = var.environment == "production"
    }
  }
}
