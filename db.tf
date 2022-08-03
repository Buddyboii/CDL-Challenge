# Create db subnet for DB instance
resource "aws_db_subnet_group" "terra-db" {
  name       = "terradb"
  subnet_ids = [aws_subnet.private-a.id, aws_subnet.private-b.id]

  tags = {
    Name = "Terra DB"
  }
}

# Create postgres DB instance
resource "aws_db_instance" "terra-db" {
  identifier              = var.db_identifier
  instance_class          = var.instance_class
  engine                  = var.engine
  engine_version          = var.engine_version
  username                = var.db_username
  password                = var.db_password
  allocated_storage       = 10
  max_allocated_storage   = 100
  skip_final_snapshot     = true
  publicly_accessible     = false
  availability_zone       = aws_subnet.private-a.availability_zone
  db_subnet_group_name    = aws_db_subnet_group.terra-db.name
  vpc_security_group_ids  = [aws_security_group.terra-web-access.id]
  backup_retention_period = 1
  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
}

# Create Read Replica
resource "aws_db_instance" "terra-db-replica" {
  instance_class         = var.instance_class
  replicate_source_db    = aws_db_instance.terra-db.id
  skip_final_snapshot    = true
  availability_zone      = aws_subnet.private-b.availability_zone
  vpc_security_group_ids = [aws_security_group.terra-web-access.id]
  identifier             = var.db_replica_identifier
}




output "rds_hostname" {
  description = "RDS instance hostname"
  value       = aws_db_instance.terra-dbn.address
  sensitive   = true
}

output "rds_username" {
  description = "RDS instance root username"
  value       = aws_db_instance.terra-db.username
  sensitive   = true
}