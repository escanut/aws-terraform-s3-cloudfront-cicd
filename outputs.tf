output "s3_bucket_name" {
    description =  "The name used for the s3 bucket"
    value = aws_s3_bucket.website_storage.id
}

output "s3_website_url" {
  description = "s3 website endpoint"
  value = "http://${aws_s3_bucket_website_configuration.website_storage.website_endpoint}"
}

output "cloudfront_url" {
  description = "cloudfront url used for distribution"
  value = "https:/${aws_cloudfront_distribution.website_storage.domain_name}"
}

output "cloudfront_distribution_id" {
    description = "Cloudfront distribution ID for cache invalidation"
    value = aws_cloudfront_distribution.website_storage.id
  
}

output "github_actions_role_amazon_resource_name" {
  description = "IAM role ARN for Github actions"
  value = aws_iam_role.github_actions.arn
}