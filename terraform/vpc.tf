data "aws_availability_zones" "available" {}

locals {
  name     = "ex-${basename(path.cwd)}-dev"
  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source                             = "terraform-aws-modules/vpc/aws"
  name                               = local.name
  cidr                               = local.vpc_cidr
  azs                                = local.azs
  public_subnets                     = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  database_subnets                   = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 4)]
  create_database_subnet_route_table = true
  create_database_subnet_group       = true
  create_igw                         = true
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.public_route_table_ids
}

resource "aws_vpc_endpoint" "dynamo_db_endpoint" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.public_route_table_ids
}

resource "aws_vpc_endpoint" "secrets_manager_endpoint" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.sm_sg.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "bedrock_endpoint" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.bedrock_sg.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "lambda_endpoint" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.lambda"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.lambda_egress_all_sg]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true
}

resource "aws_security_group" "bedrock_sg" {
  name   = "bedrock-runtime-sg-dev"
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Bedrock runtime sg"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sm_sg" {
  name   = "secret-manager-sg-dev"
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Secrets Manager"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_egress_all_sg" {
  name   = "public-lambda-sg"
  vpc_id = module.vpc.vpc_id
  egress {
    description = "Lambda egress all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "database_sg" {
  name   = "database-sg-main-dev"
  vpc_id = module.vpc.vpc_id
  ingress {
    description     = "VectorDB ingress"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_egress_all_sg, aws_security_group.jumpbox_sg.id]
  }
}

resource "aws_security_group" "jumpbox_sg" {
  name   = "jumpbox-sg-dev"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dynamo_db_sg" {
  name   = "dynamo-sg-dev"
  vpc_id = module.vpc.vpc_id
  ingress {
    description     = "Dynamo DB ingress"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_egress_all_sg]
  }
}
