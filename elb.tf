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

# ------------------------------
# Listener
# ------------------------------
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code  = 200
    }
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.tokyo_cert.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTPS」です"
      status_code  = 200
    }
  }
}

resource "aws_alb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener_rule" "https_to_target_group" {
  listener_arn = aws_alb_listener.https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_fargate.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ------------------------------
# target group
# ------------------------------
resource "aws_lb_target_group" "ecs_fargate" {
  name                 = "${var.environment}-ecs-fargate"
  target_type          = "ip"
  vpc_id               = aws_vpc.example.id
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/greeting/maga"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = 8080
    protocol            = "HTTP"
  }

  depends_on = [
    aws_lb.example
  ]
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
