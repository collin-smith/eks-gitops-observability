# terraform/modules/eks

EKS cluster module: control plane (in `terraform/modules/vpc`'s public +
private subnets), a managed node group (EC2, in the private subnets only),
IAM roles for both, and an IAM OIDC provider for IRSA (pods assuming IAM
roles via a Kubernetes service account — no specific IRSA-scoped roles are
created yet, just the provider later stages can hang roles off of).

Cluster API endpoint is both privately and publicly reachable by default
(`public_access_cidrs` defaults to `0.0.0.0/0` — restrict this to your own
IP for anything beyond a demo). Node group defaults to 2x `t3.medium`,
min 1 / max 3.
