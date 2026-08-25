variable "cluster_name" {
  type = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
  default     = "1.30"
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
  type    = list(string)
  default = ["t3.medium"]
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
