output "cluster_name" {
  value = module.eks.cluster_id
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer" {
  value = try(module.eks.cluster_oidc_issuer, "")
}

output "ecr_repository_url" {
  description = "ECR repository URL (without tag)"
  value       = aws_ecr_repository.app.repository_url
}

output "ecr_image_with_tag" {
  description = "Full ECR image URI including tag"
  value       = "${aws_ecr_repository.app.repository_url}:${var.image_tag}"
}
