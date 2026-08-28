variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's IAM OIDC provider (from the eks module) — the trust anchor for the controller's IRSA role"
  type        = string
}

variable "oidc_provider_url" {
  description = "The cluster's OIDC issuer URL, https:// included (from the eks module)"
  type        = string
}

variable "node_iam_role_arn" {
  description = "IAM role ARN that Karpenter-launched nodes assume. This module reuses the managed node group's role rather than creating a second one — the controller policy grants iam:PassRole on exactly this ARN."
  type        = string
}

variable "node_iam_role_name" {
  description = "Name of the same role — the EC2NodeClass references it by name, and Karpenter creates/manages the instance profile for it."
  type        = string
}

variable "cluster_security_group_id" {
  description = "The EKS-managed cluster security group — tagged for discovery so Karpenter nodes attach it and can reach the API server / other nodes."
  type        = string
}

variable "karpenter_namespace" {
  description = "Namespace the Karpenter controller runs in — must match the ServiceAccount the Helm release creates."
  type        = string
  default     = "kube-system"
}

variable "karpenter_service_account" {
  type    = string
  default = "karpenter"
}

variable "tags" {
  type    = map(string)
  default = {}
}
