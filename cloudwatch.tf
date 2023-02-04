# ------------------------------
# CloudWatch
# ------------------------------
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/dev/nginx/web"
  retention_in_days = 180
}
