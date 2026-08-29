output "controller_role_arn" {
  description = "Annotate the controller's ServiceAccount with this (Helm: serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn)"
  value       = aws_iam_role.this.arn
}
