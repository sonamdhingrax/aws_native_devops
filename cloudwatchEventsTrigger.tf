resource "aws_cloudwatch_event_rule" "app_codebuild_trigger" {
  name = "${var.app_name}_codebuild-trigger"

  event_pattern = <<EOF
{
  "source": [
    "aws.codecommit"
  ],
  "resources": [
    "arn:aws:codecommit:${var.region}:${var.account_id}:${var.app_name}"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ],
    "referenceType": [
      "branch"
    ],
    "referenceName": [
      "master"
    ]
  }
}
EOF
}

resource "aws_iam_role" "aws_events_invoke_codebuild" {
  name = "aws_events_invoke_codebuild"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "events.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

# Create the IAM policy for the ECS task
resource "aws_iam_policy" "aws_events_invoke_codebuild" {
  name   = "aws_events_invoke_codebuild"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:StartBuild"
            ],
            "Resource": [
                "${aws_codebuild_project.app_build.arn}"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  role       = aws_iam_role.aws_events_invoke_codebuild.name
  policy_arn = aws_iam_policy.aws_events_invoke_codebuild.arn
}


# Create the CloudWatch Events target for the CodeBuild project
resource "aws_cloudwatch_event_target" "app_codebuild_target" {
  rule      = aws_cloudwatch_event_rule.app_codebuild_trigger.name
  target_id = "codebuild"
  arn       = aws_codebuild_project.app_build.arn
  role_arn  = aws_iam_role.aws_events_invoke_codebuild.arn
}
