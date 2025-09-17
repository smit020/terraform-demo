resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_oauth_token
}

resource "aws_codebuild_project" "build" {
  name          = "build-myapp"
  service_role  = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      name  = "GITHUB_OAUTH_TOKEN"
      value = var.github_oauth_token
      type  = "PLAINTEXT"
    }

    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "ECR_REPOSITORY"
      value = var.ecr_repo_name
    }

    environment_variable {
      name  = "EKS_CLUSTER_NAME"
      value = var.cluster_name
    }
  }

  source {
    type      = "GITHUB"
    location  = "https://github.com/${var.github_owner}/${var.github_repo}.git"
    buildspec = "buildspec.yml"
  }
}

resource "aws_codebuild_webhook" "build_webhook" {
  project_name = aws_codebuild_project.build.name
}
