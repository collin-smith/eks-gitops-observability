variable "name" {
  description = "Name prefix applied to all VPC resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones to spread subnets across (EKS requires at least 2)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets, one per AZ, same order as var.azs"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private (worker node) subnets, one per AZ, same order as var.azs"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS cluster name these subnets belong to, used for the kubernetes.io/cluster discovery tag"
  type        = string
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway shared by all private subnets instead of one per AZ. Cheaper and less resilient — a reasonable tradeoff for a portfolio/demo environment, not for production HA."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
