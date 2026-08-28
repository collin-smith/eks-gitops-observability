output "controller_role_arn" {
  description = "Annotate Karpenter's ServiceAccount with this (Helm: serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn)"
  value       = aws_iam_role.controller.arn
}

output "interruption_queue_name" {
  description = "Helm: settings.interruptionQueue"
  value       = aws_sqs_queue.interruption.name
}

output "node_iam_role_name" {
  description = "Pass-through — the EC2NodeClass 'role' field. Same role the managed node group uses."
  value       = var.node_iam_role_name
}
