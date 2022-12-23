resource "aws_codecommit_repository" "app_repo" {
  repository_name = var.app_name
  description     = "This is the ${var.app_name} App Repository"
  # lifecycle {
  #   prevent_destroy = true
  # }
}
