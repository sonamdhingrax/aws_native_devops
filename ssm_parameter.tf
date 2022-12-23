resource "aws_ssm_parameter" "app_version" {
  name        = "${var.app_name}_version"
  type        = "String"
  value       = "null"
  description = "Stores the Latest version of the ${var.app_name} app which will be used to tag the container image in ECR"
}
