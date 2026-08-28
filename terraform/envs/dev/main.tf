module "vpc" {
  source = "../../modules/vpc"

  name                 = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  cluster_name         = var.cluster_name
  single_nat_gateway   = var.single_nat_gateway
}

module "eks" {
  source = "../../modules/eks"

  cluster_name             = var.cluster_name
  cluster_version          = var.cluster_version
  vpc_id                   = module.vpc.vpc_id
  private_subnet_ids       = module.vpc.private_subnet_ids
  control_plane_subnet_ids = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  public_access_cidrs      = var.public_access_cidrs
  node_instance_types      = var.node_instance_types
  node_desired_size        = var.node_desired_size
  node_min_size            = var.node_min_size
  node_max_size            = var.node_max_size
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name
}

# Stage 7: Karpenter node autoscaling. The managed node group stays as
# baseline capacity (ArgoCD, kube-prometheus-stack, Karpenter itself);
# Karpenter provisions extra nodes on demand for workload bursts.
module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name              = var.cluster_name
  oidc_provider_arn         = module.eks.oidc_provider_arn
  oidc_provider_url         = module.eks.oidc_provider_url
  node_iam_role_arn         = module.eks.node_group_role_arn
  node_iam_role_name        = module.eks.node_group_role_name
  cluster_security_group_id = module.eks.cluster_security_group_id
  discovery_subnet_ids      = module.vpc.private_subnet_ids
}
