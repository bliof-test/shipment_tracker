data "aws_secretsmanager_secret" "secret" {
  name = format("%s/%s/DB", var.environment, var.service_name)
}

data "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = data.aws_secretsmanager_secret.secret.id
}

data "aws_vpc" "vpc" {
  tags = {
    Name = format("%s-vpc", local.environment.name)
  }
}

data "aws_subnet_ids" "subnet_ids" {
  vpc_id = data.aws_vpc.vpc.id
  filter {
    name   = "tag:Name"
    values = [format("%s-vpc-private-*", local.environment.name)]
  }
}
