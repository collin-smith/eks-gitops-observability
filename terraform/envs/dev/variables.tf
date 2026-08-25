variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "eks-gitops-observability-dev"
}

variable "cluster_version" {
  description = "See module.eks's cluster_version — this default goes stale as EKS versions age out of support; check `aws eks describe-cluster-versions` before applying."
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "single_nat_gateway" {
  description = "Single shared NAT gateway instead of one per AZ — cheaper, acceptable for a demo environment"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public Kubernetes API endpoint. Override in terraform.tfvars with your own IP/32 before applying."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "New AWS accounts may be restricted to free-tier-eligible types only — see module.eks's node_instance_types for how to check."
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

variable "ecr_repository_name" {
  type    = string
  default = "eks-gitops-observability/demo-app"
}
