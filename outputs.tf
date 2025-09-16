output "cluster_name"        { value = module.eks.cluster_id }
output "cluster_endpoint"    { value = module.eks.cluster_endpoint }
output "cluster_oidc_issuer" { value = try(module.eks.cluster_oidc_issuer, "") }
output "ecr_repository_url"  { value = aws_ecr_repository.app.repository_url }
output "ecr_image_with_tag"  { value = "${aws_ecr_repository.app.repository_url}:${var.image_tag}" }

output "rds_target_endpoint" { value = aws_db_instance.pg.address }
output "rds_target_port"     { value = aws_db_instance.pg.port }

output "restore_s3_bucket"   { value = aws_s3_bucket.restore_bucket.bucket }
