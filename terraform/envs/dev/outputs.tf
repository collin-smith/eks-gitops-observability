output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  description = "Run this to point kubectl at the new cluster"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

# Stage 7 — fed into argocd/apps/karpenter.yaml's Helm values.
output "karpenter_controller_role_arn" {
  value = module.karpenter.controller_role_arn
}

output "karpenter_interruption_queue" {
  value = module.karpenter.interruption_queue_name
}

output "karpenter_node_role_name" {
  description = "The EC2NodeClass 'role' field in argocd/apps/karpenter-nodepool.yaml"
  value       = module.karpenter.node_iam_role_name
}
