resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-${var.environment}-backend"
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the ${var.image_count_to_keep} most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.image_count_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
