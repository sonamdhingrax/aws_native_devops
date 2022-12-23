resource "aws_iam_role" "CodeBuildBasePolicy-app" {
  name = "CodeBuildBasePolicy-${var.app_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "CodeBuildBasePolicy" {
  role = aws_iam_role.CodeBuildBasePolicy-app.name

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "ecr:GetRegistryPolicy",
                "ecr:BatchImportUpstreamImage",
                "ecr:DescribeRegistry",
                "ecr:DescribePullThroughCacheRules",
                "ecr:GetAuthorizationToken",
                "ecr:PutRegistryScanningConfiguration",
                "ecr:GetRegistryScanningConfiguration"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "ecr:PutImageTagMutability",
                "ecr:StartImageScan",
                "ecr:DescribeImageReplicationStatus",
                "ecr:ListTagsForResource",
                "ecr:UploadLayerPart",
                "ecr:BatchGetRepositoryScanningConfiguration",
                "ecr:ListImages",
                "codebuild:CreateReport",
                "logs:CreateLogStream",
                "codebuild:UpdateReport",
                "ecr:CompleteLayerUpload",
                "codebuild:BatchPutCodeCoverages",
                "ecr:TagResource",
                "ecr:DescribeRepositories",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetLifecyclePolicy",
                "ecr:DescribeImageScanFindings",
                "ecr:GetLifecyclePolicyPreview",
                "ecr:GetDownloadUrlForLayer",
                "ecr:PutImageScanningConfiguration",
                "codecommit:GitPull",
                "s3:GetBucketAcl",
                "logs:CreateLogGroup",
                "logs:PutLogEvents",
                "ecr:PutImage",
                "s3:PutObject",
                "s3:GetObject",
                "codebuild:CreateReportGroup",
                "ecr:UntagResource",
                "ecr:BatchGetImage",
                "ecr:DescribeImages",
                "ecr:StartLifecyclePolicyPreview",
                "ecr:InitiateLayerUpload",
                "s3:GetBucketLocation",
                "codebuild:BatchPutTestCases",
                "s3:GetObjectVersion",
                "ecr:GetRepositoryPolicy"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-2:${var.account_id}:log-group:/aws/codebuild/openstor_build",
                "arn:aws:logs:eu-west-2:${var.account_id}:log-group:/aws/codebuild/openstor_build:*",
                "arn:aws:ecr:eu-west-2:${var.account_id}:repository/openstor",
                "arn:aws:s3:::codepipeline-eu-west-2-*",
                "arn:aws:codecommit:eu-west-2:${var.account_id}:openstor",
                "arn:aws:codebuild:eu-west-2:${var.account_id}:report-group/openstor_build-*"
            ]
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "ssm:PutParameter",
                "ssm:GetParametersByPath",
                "ssm:GetParameters"
            ],
            "Resource": "arn:aws:ssm:eu-west-2:${var.account_id}:parameter/${aws_ssm_parameter.app_version.name}"
        }        
    ]
}
POLICY
}

resource "aws_s3_bucket" "app_bucket" {
  bucket = "${var.app_name}-bucket-2022"
}

resource "aws_s3_bucket_acl" "app_bucket_acl" {
  bucket = aws_s3_bucket.app_bucket.id
  acl    = "private"
}

resource "aws_codebuild_project" "app_build" {
  name          = "${var.app_name}_build"
  description   = "Create a docker image of the openstor app"
  build_timeout = "5"
  service_role  = aws_iam_role.CodeBuildBasePolicy-app.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = aws_s3_bucket.app_bucket.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ECR_REPO_NAME"
      value = var.app_name
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.account_id
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/${var.app_name}_build"
      stream_name = "/aws/codebuild/${var.app_name}_build"
    }
  }

  source {
    type            = "CODECOMMIT"
    location        = "https://git-codecommit.${var.region}.amazonaws.com/v1/repos/${var.app_name}"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }
}
