resource "aws_security_group" "rds_access" {
  name        = "${var.env}-rds-access-from-author"
  description = "Database access from the application subnet"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = "${var.application_cidrs}"
  }

  tags {
    Name = "${var.env}-db-security-group"
  }
}

resource "aws_db_instance" "author_database" {
  allocated_storage           = 10
  identifier                  = "${var.env}-author-rds"
  engine                      = "postgres"
  engine_version              = "9.4.7"
  allow_major_version_upgrade = "false"
  instance_class              = "db.t2.small"
  name                        = "author"
  username                    = "author"
  password                    = "${var.author_database_password}"
  multi_az                    = false
  publicly_accessible         = false
  backup_retention_period     = 0
  db_subnet_group_name        = "${var.env}-eq-rds"
  vpc_security_group_ids      = ["${aws_security_group.rds_access.id}"]
  storage_type                = "gp2"
  apply_immediately           = true
  skip_final_snapshot         = true

  tags {
    Name        = "${var.env}-author-db-instance"
    Environment = "${var.env}"
  }
}
