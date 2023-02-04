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
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

resource "aws_ecs_service" "example" {
  name                              = "${var.project}-${var.environment}-service"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
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

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

module "nginx_sg" {
  source = "./security_group"
  name   = "${var.environment}-nginx-sg"
  vpc_id = aws_vpc.example.id
  ingress_ports = [
    { port = "80", cidr_blocks = ["0.0.0.0/0"] },
  ]
}
