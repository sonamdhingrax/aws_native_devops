resource "aws_codecommit_repository" "test" {
  repository_name = "openstor"
  description     = "This is the Openstor App Repository"
  # lifecycle {
  #   prevent_destroy = true
  # }
}
