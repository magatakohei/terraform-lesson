# ------------------------------
# CloudWatch
# ------------------------------
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/dev/app/web"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
  name              = "/dev/ecs-scheduled-tasks/example"
  retention_in_days = 180
}

resource "aws_cloudwatch_log_group" "operation" {
  name              = "/operation"
  retention_in_days = 180
}

# ------------------------------
# event rule
# ------------------------------
resource "aws_cloudwatch_event_rule" "example_batch" {
  name                = "example-batch"
  description         = "とても重要なバッチです"
  schedule_expression = "cron(*/2 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "example_batch" {
  target_id = "example-batch"
  rule      = aws_cloudwatch_event_rule.example_batch.name
  role_arn  = module.ecs_events_role.iam_role_arn
  arn       = aws_ecs_cluster.example.arn

  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    platform_version    = "1.4.0"
    task_definition_arn = aws_ecs_task_definition.example_batch.arn

    network_configuration {
      assign_public_ip = "false"
      subnets          = [aws_subnet.private_1a.id]
    }
  }
}

# ------------------------------
# CloudWatch IAM
# ------------------------------
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:ap-northeast-1:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::*:role/cloudwatch-logs"]
  }
}

module "cloudwatch_logs_role" {
  source     = "./iam_role"
  name       = "cloudwatch-logs"
  identifier = "logs.ap-northeast-1.amazonaws.com"
  policy     = data.aws_iam_policy_document.cloudwatch_logs.json
}

# ------------------------------
# CloudWatch Subscription filter
# ------------------------------
resource "aws_cloudwatch_log_subscription_filter" "example" {
  name            = "example"
  log_group_name  = aws_cloudwatch_log_group.for_ecs_scheduled_tasks.name
  destination_arn = aws_kinesis_firehose_delivery_stream.example.arn
  filter_pattern  = "[]"
  role_arn        = module.cloudwatch_logs_role.iam_role_arn
}
