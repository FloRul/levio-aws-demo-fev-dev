resource "aws_db_instance" "vector_db" {
  vpc_security_group_ids       = [aws_security_group.database_sg.id]
  db_subnet_group_name         = module.vpc.database_subnet_group
  allocated_storage            = 10
  storage_type                 = "gp2"
  engine                       = "postgres"
  engine_version               = "15.5"
  instance_class               = "db.t3.micro"
  identifier                   = "vector-db-dev"
  username                     = var.db_admin_user
  password                     = data.aws_secretsmanager_secret_version.password.secret_string
  publicly_accessible          = false
  port                         = 5432
  skip_final_snapshot          = true
  allow_major_version_upgrade  = true
  auto_minor_version_upgrade   = true
  performance_insights_enabled = false
  apply_immediately            = true
  parameter_group_name         = aws_db_parameter_group.default.name
  db_name                      = var.db_name
}

resource "aws_db_parameter_group" "default" {
  name   = "rds-pg"
  family = "postgres15"

  parameter {
    name  = "rds.force_ssl"
    value = 0
  }
}