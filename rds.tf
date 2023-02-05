# ------------------------------
# RDS SSM
# ------------------------------
data "aws_ssm_parameter" "database_name" {
  name = "/${var.environment}/database/name"
}

data "aws_ssm_parameter" "database_username" {
  name = "/${var.environment}/database/username"
}

data "aws_ssm_parameter" "database_password" {
  name = "/${var.environment}/database/password"
}
# ------------------------------
# RDS Security Group
# ------------------------------
module "database_sg" {
  source = "./security_group"
  name   = "database-sg"
  vpc_id = aws_vpc.example.id
  ingress_ports = [
    { port = "3306", cidr_blocks = [aws_vpc.example.cidr_block] },
  ]
}

resource "aws_db_subnet_group" "database_sg_group" {
  name        = "${var.project}-${var.environment}-database-subnet-group"
  description = "${var.project}-${var.environment}-database-subnet-group"
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1c.id,
  ]
}


# ------------------------------
# RDS Cluster
# ------------------------------
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.project}-${var.environment}-database-cluster"

  db_subnet_group_name   = aws_db_subnet_group.database_sg_group.name
  vpc_security_group_ids = [module.database_sg.security_group_id]

  engine         = "aurora-mysql"
  engine_version = "5.7.mysql_aurora.2.11.0"
  port           = "3306"

  database_name   = data.aws_ssm_parameter.database_name.value
  master_username = data.aws_ssm_parameter.database_username.value
  master_password = data.aws_ssm_parameter.database_password.value

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  storage_encrypted = true
  kms_key_id        = aws_kms_key.example.arn
  apply_immediately = false

  // 削除時 true
  skip_final_snapshot = true
  // 削除時 false
  deletion_protection = false
}

# ------------------------------
# RDS Cluster Instance
# ------------------------------
resource "aws_rds_cluster_instance" "this" {
  count              = 2
  identifier         = "${var.project}-${var.environment}-database-cluster-instance-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id

  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version

  instance_class = "db.t3.small"

  apply_immediately = false
}

# ------------------------------
# RDS Cluster config
# ------------------------------
resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.project}-${var.environment}-database-cluster-parameter-group"
  family = "aurora-mysql5.7"

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }
}

# ------------------------------
# SSM DB url
# ------------------------------
resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.environment}/database/url"
  type  = "String"
  value = aws_rds_cluster.this.endpoint
}
