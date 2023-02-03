# ------------------------------
# ALB
# ------------------------------
resource "aws_lb" "example" {
  name                       = "${var.project}-${var.environment}-alb"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  enable_deletion_protection = false

  subnets = [
    aws_subnet.public_1a.id,
    aws_subnet.public_1c.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.alb_security_group.security_group_id
  ]

  tags = {
    Name    = "${var.project}-${var.environment}-alb"
    Project = var.project
    Env     = var.environment
  }
}

module "alb_security_group" {
  source = "./security_group"
  name   = "${var.environment}-alb-sg"
  vpc_id = aws_vpc.example.id
  ingress_ports = [
    { port = "80", cidr_blocks = ["0.0.0.0/0"] },
    { port = "443", cidr_blocks = ["0.0.0.0/0"] },
    { port = "8080", cidr_blocks = ["0.0.0.0/0"] },
  ]
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
