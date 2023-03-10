# ------------------------------
# Kinesis Data Firehose IAM
# ------------------------------
data "aws_iam_policy_document" "kinesis_data_firehose" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}",
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}/*"
    ]
  }
}

module "kinesis_data_firehose_role" {
  source     = "./iam_role"
  name       = "kinesis-data-firehose"
  identifier = "firehose.amazonaws.com"
  policy     = data.aws_iam_policy_document.kinesis_data_firehose.json
}

# ------------------------------
# Kinesis Data Firehose
# ------------------------------
resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = module.kinesis_data_firehose_role.iam_role_arn
    bucket_arn         = aws_s3_bucket.cloudwatch_logs.arn
    prefix             = "ecs-scheduled-tasks/example/"
    compression_format = "GZIP"
  }
}
