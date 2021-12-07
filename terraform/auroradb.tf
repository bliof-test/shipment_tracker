resource "aws_security_group_rule" "legacy_vpc" {
  description              = "Allow traffic from legacy VPC"
  security_group_id        = aws_security_group.security_group.id
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = format("755865716437/%s", var.legacy_vpc_security_group_id)
}

resource "aws_security_group_rule" "vpc" {
  description       = "Allow traffic from VPC"
  security_group_id = aws_security_group.security_group.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks = [
    data.aws_vpc.vpc.cidr_block,
  ]
}

#tfsec:ignore:FCC004
resource "aws_security_group" "security_group" {
  name        = format("%s-%s-db-sg", var.environment, var.service_name)
  description = format("%s database cluster", var.service_name)
  vpc_id      = data.aws_vpc.vpc.id
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = format("%s-%s", var.environment, var.service_name)
  subnet_ids = data.aws_subnet_ids.subnet_ids.ids
}

resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier = var.service_name
  database_name      = "shipment_tracker"
  engine             = "aurora-postgresql"
  engine_version     = "10.14"
  engine_mode        = "serverless"
  scaling_configuration {
    auto_pause   = false
    min_capacity = 8
    max_capacity = 8
  }
  backup_retention_period   = 30
  skip_final_snapshot       = !local.environment.is.production
  final_snapshot_identifier = var.service_name
  copy_tags_to_snapshot     = true
  deletion_protection       = local.environment.is.production
  master_username           = "postgres"
  master_password           = jsondecode(data.aws_secretsmanager_secret_version.secret_version.secret_string)["PASSWORD"]
  vpc_security_group_ids    = [aws_security_group.security_group.id]
  db_subnet_group_name      = aws_db_subnet_group.subnet_group.name
  storage_encrypted         = true
  kms_key_id                = aws_kms_alias.alias.target_key_arn
}
