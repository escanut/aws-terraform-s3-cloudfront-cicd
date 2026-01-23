variable "aws_region" {
    description = "AWS region used for resources"
    type = string
    default = "us-east-1"
}

variable "project_name" {

        description = "Project name for tagging"
        type = string
}

variable "bucket_name" {
    description = "S3 bucket name"
    type = string
}

variable "github_username" {
  description = "Github username for OIDC policy setup"
  type = string
}

variable "repo_name" {
    description = "Github Repo"
    type = string
  
}