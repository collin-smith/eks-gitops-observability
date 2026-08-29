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

variable "namespace" {
  description = "Namespace the controller runs in — must match the ServiceAccount the Helm release creates."
  type        = string
  default     = "kube-system"
}

variable "service_account" {
  description = "ServiceAccount name the Helm release creates and the IRSA trust policy is scoped to."
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "tags" {
  type    = map(string)
  default = {}
}
