variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane. EKS stops publishing managed-node-group AMIs once a version ages out of support, so this default will itself go stale over time — before applying, check what's currently STANDARD_SUPPORT with `aws eks describe-cluster-versions --query \"clusterVersions[?versionStatus=='STANDARD_SUPPORT'].clusterVersion\"` and override via tfvars if this default no longer appears in that list."
  type        = string
  default     = "1.34"
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Private subnets the managed node group's worker nodes launch into"
  type        = list(string)
}

variable "control_plane_subnet_ids" {
  description = "Subnets the EKS control plane's cross-account ENIs are placed in — public + private, so both endpoint access paths work"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the Kubernetes API server endpoint is reachable from outside the VPC"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint. Left open for a portfolio demo — restrict to your own IP/32 in real use."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "New AWS accounts are often restricted to free-tier-eligible instance types only (an anti-fraud guardrail, not a hard account limit) — if CreateNodegroup fails with 'not eligible for Free Tier', run `aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true` and override this via tfvars with whatever it returns."
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 1
}

variable "node_max_size" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}
