//module "author-database" {
//  source                           = "github.com/ONSdigital/eq-terraform//survey-runner-database"
//  env                              = "${var.env}"
//  aws_access_key                   = "${var.aws_access_key}"
//  aws_secret_key                   = "${var.aws_secret_key}"
//  vpc_id                           = "${data.aws_alb.eq.vpc_id}"
//  application_cidrs                = ["10.30.20.32/28", "10.30.20.48/28", "10.30.20.64/28"]
//  database_cidrs                   = "${var.database_cidrs}"
//  private_route_table_ids          = ["rtb-b32fded5", "rtb-182ddc7e", "rtb-9d2edffb"]
//  multi_az                         = false
//  backup_retention_period          = 0
//  database_apply_immediately       = true
//  database_instance_class          = "db.t2.small"
//  database_allocated_storage       = "10"
//  database_free_memory_alert_level = "128"
//  database_name                    = "eq-author"
//  database_user                    = "eq-author"
//  database_password                = "eq-author"
//}


resource "aws_db_instance" "author_database" {
  allocated_storage           = 10
  identifier                  = "${var.env}-author-rds"
  engine                      = "postgres"
  engine_version              = "9.4.7"
  allow_major_version_upgrade = "false"
  instance_class              = "db.t2.small"
  name                        = "author"
  username                    = "eq-author"
  password                    = "eq-author"
  multi_az                    = false
  publicly_accessible         = false
  backup_retention_period     = 0
  db_subnet_group_name        = "staging-eq-rds"
  vpc_security_group_ids      = ["sg-5d573125"]
  storage_type                = "gp2"
  apply_immediately           = true
  skip_final_snapshot         = true

  tags {
    Name        = "${var.env}-author-db-instance"
    Environment = "${var.env}"
  }
}
