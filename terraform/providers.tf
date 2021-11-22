provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Repository  = "github.com/FundingCircle/shipment_tracker"
      Environment = var.environment
      Domain      = "platform"
      Team        = "platform-engineering"
      Managed_by  = "terraform"
      Created_by  = "platform-engineering@fundingcircle.com"
    }
  }

  assume_role {
    role_arn     = local.role.drone
    session_name = var.service_name
  }
}
