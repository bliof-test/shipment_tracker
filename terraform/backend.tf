terraform {
  required_version = "= 0.11.14"

  backend "s3" {
    bucket         = "fc-tfstate"
    region         = "eu-west-1"
    key            = "global/pagerduty/shipment_tracker.tfstate"
    dynamodb_table = "tfstate-lock"
    role_arn       = "arn:aws:iam::721867752048:role/terraform"
  }
}
