output "github_role_arn" {
  description = "Put this in the AWS_STATE_ROLE_ARN secret of every GitHub environment."
  value       = aws_iam_role.github.arn
}

output "state_bucket" {
  value = aws_s3_bucket.state.bucket
}
