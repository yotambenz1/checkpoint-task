locals {
  repos_kms = [
    "worker-app", "flask-app"
  ]
}

resource "aws_ecr_repository" "checkpoint_ecrs" {
  for_each             = toset(local.repos_kms)
  name                 = "${var.environment}-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
  encryption_configuration {
    encryption_type = "KMS"
  }
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "ecr_policy_kms" {
  for_each   = toset(local.repos_kms)
  repository = aws_ecr_repository.checkpoint_ecrs[each.key].name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 2,
            "description": "retention policy for all ECR registry images to keep only last 50 images and tags",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                "countNumber": 50
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}