terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.91.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "ca-central-1"
}

resource "aws_s3_bucket" "cloudweave_s3_bucket" {
  bucket_prefix = "cloudweave"
  force_destroy = true
}

resource "aws_iam_role" "codepipeline_role" {
  name_prefix = "cloudweave-codepipeline"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "allow_s3" {
  name_prefix = "allow_s3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject"
      ]
      Resource = "${aws_s3_bucket.cloudweave_s3_bucket.arn}/*"
    }]

  })
}

resource "aws_iam_role_policy_attachment" "attach-codepipeline-s3-policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.allow_s3.arn
}

resource "aws_iam_policy" "allow_codestar-connections" {
  name_prefix = "allow_codestar-connections"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "codestar-connections:UseConnection"
      ]
      Resource = var.github_codestar_connection_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach-codepipeline-codestar-connections-policy" {
  role = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.allow_codestar-connections.arn
}

resource "aws_iam_policy" "allow_codebuild" {
  name_prefix = "allow_codebuild"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "codebuild:StartBuild"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach-codepipeline-codebuild-policy" {
  role = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.allow_codebuild.arn
}

resource "aws_iam_role" "codebuild_role" {
  name_prefix = "cloudweave-codebuild"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_codebuild_project" "cloudweave" {
  name = "cloudweave_build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }
  source {
    type = "CODEPIPELINE"
  }
  environment {
    type = "LINUX_CONTAINER"
    image = "aws/codebuild/standard:5.0"
    compute_type = "BUILD_GENERAL1_SMALL"
  }
}

resource "aws_codepipeline" "cloudweave-codepipeline" {
  role_arn = aws_iam_role.codepipeline_role.arn
  name     = "cloudweave-codepipeline"
  artifact_store {
    location = aws_s3_bucket.cloudweave_s3_bucket.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      version          = "1"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      output_artifacts = ["SourceOutput"]
      configuration = {
        ConnectionArn    = var.github_codestar_connection_arn
        FullRepositoryId = var.github_repository_id
        BranchName       = var.github_main_branch
      }
    }
  }
  stage {
    name = "Build"
    action {
      name             = "BuildAction"
      category         = "Build"
      version          = "1"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      configuration = {
        ProjectName = aws_codebuild_project.cloudweave.name
      }
    }
  }
}
