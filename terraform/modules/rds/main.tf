resource "aws_db_subnet_group" "this" {
  name       = "banking-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "banking-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = "banking-platform"
  }
}

resource "aws_security_group" "this" {
  name        = "banking-${var.environment}-rds-sg"
  description = "Security group for banking RDS"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "banking-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = "banking-platform"
  }
}

resource "aws_db_instance" "this" {
  identifier = "banking-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = "16"

  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 5432

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  publicly_accessible = false

  backup_retention_period = 1

  skip_final_snapshot = true

  deletion_protection = false

  multi_az = false

  tags = {
    Name        = "banking-${var.environment}-postgres"
    Environment = var.environment
    Project     = "banking-platform"
  }
}


resource "aws_secretsmanager_secret" "database" {
  name        = "banking/${var.environment}/database"
  description = "Database credentials for banking ${var.environment} environment"

  tags = {
    Environment = var.environment
    Project     = "banking-platform"
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    database = var.db_name
  })
}

