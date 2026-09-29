
resource "aws_s3_bucket" "website_storage" {
    bucket = "${var.project_name}-${random_id.suffix.hex}"
    
    tags = {
        #To easily seperate this bucket from the one used to hold Terraform State
        Project = var.project_name
        Managedby = "Terraform"
    }
}

#To aid with uniqueness of s3 bucket name
resource "random_id" "suffix" {
    byte_length = 4
  
}



#s3 bucket public accesss override
resource "aws_s3_bucket_public_access_block" "website_storage" {
  
    bucket = aws_s3_bucket.website_storage.id

    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
}


resource "aws_s3_bucket_website_configuration" "website_storage"{
    bucket = aws_s3_bucket.website_storage.id

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "error.html"
    }
}

#s3 bucket Access policy
resource "aws_s3_bucket_policy" "website_storage" {

    bucket = aws_s3_bucket.website_storage.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Sid =  "PublicReadGetObject"
            Effect = "Allow"
            Principal = "*"
            Action = "s3:GetObject"
            Resource = "${aws_s3_bucket.website_storage.arn}/*"
            }
        ]
    })

    depends_on = [ aws_s3_bucket_public_access_block.website_storage ]
}

#Cloudfront resource setup
resource "aws_cloudfront_distribution" "website_storage" {
  
  enabled = true
  default_root_object = "index.html"
  price_class = "PriceClass_100"


     origin {

        domain_name = aws_s3_bucket_website_configuration.website_storage.website_endpoint
        origin_id = "s3_website"

        #i am using custom_origin_config because S3 website endpoints are used like standard HTTP servers and do not support the S3 API.
        
        custom_origin_config {
            http_port = 80
            https_port = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocols = ["TLSv1.2"]
        }
    }


    default_cache_behavior {

        allowed_methods = ["GET", "HEAD", "OPTIONS"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = "s3_website"
        viewer_protocol_policy = "redirect-to-https"

        #i am deciding to forward the cookies and URL query params to reduce CloudFronts cost and efficiency
        forwarded_values {
            query_string = false
            cookies {
                forward = "none"
            }
        }

        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        cloudfront_default_certificate = true
    }

    tags = {
        Project = var.project_name
    }
 
}

#Setting up OIDC (OpenID Connect) Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {

    url = "https://token.actions.githubusercontent.com"

    client_id_list = ["sts.amazonaws.com"]

    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  
}


#IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  
    name = "${var.project_name}_githubactions_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"

        #Policy ensures GitHub Actions can assume this role via OIDC and restricts access to the specified repository
        Statement = [
            {
                Effect = "Allow"
                Principal = {
                    Federated = aws_iam_openid_connect_provider.github.arn
                }
                Action = "sts:AssumeRoleWithWebIdentity"

                Condition = {
                    StringEquals = {
                        "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"

                        #Scoped to the specific branch for security and proper production structure
                        "token.actions.githubusercontent.com:sub" = "repo:${var.github_username}/${var.repo_name}:ref:refs/heads/main"
                    }

                }

            }
        ]
    })

    tags = {
        Project = var.project_name
    }
}

# Creating the IAM Policy for the terraform S3 bucket and CloudFront Access
resource "aws_iam_role_policy" "github_actions_policy" {
  
  name = "${var.project_name}_githubactions_role_policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ]
            Resource = [
                aws_s3_bucket.website_storage.arn,
                "${aws_s3_bucket.website_storage.arn}/*"
            ]
        },

        {
            Effect = "Allow"
            Action = [
                "cloudfront:CreateInvalidation"
            ]
            Resource = aws_cloudfront_distribution.website_storage.arn
        }

    ]
  })
}