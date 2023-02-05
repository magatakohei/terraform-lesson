# ------------------------------
# ElastiCache Parameter Group
# ------------------------------
resource "aws_elasticache_parameter_group" "redis-parameter" {
  name   = "${var.project}-${var.environment}-redis-parameter-group"
  family = "redis7"

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

# ------------------------------
# ElastiCache Subnet Group
# ------------------------------
resource "aws_elasticache_subnet_group" "redis-subnet-group" {
  name       = "${var.project}-${var.environment}-redis-subnet-group"
  subnet_ids = [aws_subnet.private_1a.id, aws_subnet.private_1c.id]
}

# ------------------------------
# ElastiCache Secury Group
# ------------------------------
module "redis_sg" {
  source = "./security_group"
  name   = "redis-sg"
  vpc_id = aws_vpc.example.id
  ingress_ports = [
    { "port" : "6379", "cidr_blocks" : [aws_vpc.example.cidr_block] }
  ]
}

# ------------------------------
# ElastiCache Replication Group
# ------------------------------
resource "aws_elasticache_replication_group" "redis-replication-group" {
  replication_group_id       = "${var.project}-${var.environment}-redis-group"
  description                = "Cluster Disabled"
  engine                     = "redis"
  engine_version             = "7.0"
  num_cache_clusters         = 3
  node_type                  = "cache.t3.medium"
  snapshot_window            = "09:10-10:10"
  snapshot_retention_limit   = 7
  maintenance_window         = "mon:10:40-mon:11:40"
  automatic_failover_enabled = true
  port                       = 6379
  apply_immediately          = false
  security_group_ids         = []
  parameter_group_name       = aws_elasticache_parameter_group.redis-parameter.name
  subnet_group_name          = aws_elasticache_subnet_group.redis-subnet-group.name
}
