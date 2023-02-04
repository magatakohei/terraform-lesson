# ------------------------------
# ECS
# ------------------------------
resource "aws_ecs_cluster" "example" {
  name = "${var.project}-${var.environment}-cluster"
}

resource "aws_ecs_task_definition" "example" {
  family                   = "${var.project}-${var.environment}-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")
}

resource "aws_ecs_service" "example" {
  name                              = "${var.project}-${var.environment}-service"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1c.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_fargate.arn
    container_name   = "nginx"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "nginx_sg" {
  source = "./security_group"
  name   = "${var.environment}-nginx-sg"
  vpc_id = aws_vpc.example.id
  ingress_ports = [
    { port = "80", cidr_blocks = ["0.0.0.0/0"] },
  ]
}
