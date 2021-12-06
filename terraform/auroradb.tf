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
    min_capacity = 2
    max_capacity = 2
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

# For temporary instance with enough storage space to do pg_dump and pg_restore. After moving, destroy everything below.
#tfsec:ignore:FCC004
resource "aws_security_group" "ssm" {
  description = "For temporary VPC endpoints for SSM"
  vpc_id      = data.aws_vpc.vpc.id
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
  egress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.vpc.cidr_block]
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.aws_vpc.vpc.id
  vpc_endpoint_type   = "Interface"
  service_name        = format("com.amazonaws.%s.ssm", var.aws_region)
  security_group_ids  = [aws_security_group.ssm.id]
  subnet_ids          = [tolist(data.aws_subnet_ids.subnet_ids.ids)[0]]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = data.aws_vpc.vpc.id
  vpc_endpoint_type   = "Interface"
  service_name        = format("com.amazonaws.%s.ec2messages", var.aws_region)
  security_group_ids  = [aws_security_group.ssm.id]
  subnet_ids          = [tolist(data.aws_subnet_ids.subnet_ids.ids)[0]]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = data.aws_vpc.vpc.id
  vpc_endpoint_type   = "Interface"
  service_name        = format("com.amazonaws.%s.ssmmessages", var.aws_region)
  security_group_ids  = [aws_security_group.ssm.id]
  subnet_ids          = [tolist(data.aws_subnet_ids.subnet_ids.ids)[0]]
  private_dns_enabled = true
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_ssm_iam_role" {
  statement {
    sid = "ssm"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
    resources = ["*"]
  }

  statement {
    sid = "s3"
    actions = [
      "s3:GetEncryptionConfiguration"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ec2_ssm_iam" {
  name               = "ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_instance_profile" "ec2_ssm_iam" {
  name = "ec2-ssm"
  role = aws_iam_role.ec2_ssm_iam.name
}

resource "aws_iam_role_policy" "ec2_ssm_iam" {
  name   = "ec2-ssm-policy"
  role   = aws_iam_role.ec2_ssm_iam.id
  policy = data.aws_iam_policy_document.ec2_ssm_iam_role.json
}

resource "aws_instance" "dump_restore" {
  ami                         = "ami-05cd35b907b4ffe77"
  instance_type               = "c5.2xlarge"
  associate_public_ip_address = false
  subnet_id                   = tolist(data.aws_subnet_ids.subnet_ids.ids)[0]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_iam.name
  root_block_device {
    encrypted   = true
    kms_key_id  = aws_kms_alias.alias.target_key_arn
    volume_size = 250
  }
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  tags = {
    Name = "pg_dump pg_restore"
  }
}