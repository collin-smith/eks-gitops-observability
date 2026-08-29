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

## Node launch template — IMDS hop limit

The managed node group runs off a custom `aws_launch_template` whose only
non-default setting is `metadata_options.http_put_response_hop_limit = 2`.

EKS defaults this to 1. With hop limit 1, a request to IMDS
(`169.254.169.254`) from any pod that isn't on the host network is dropped —
the packet takes one hop crossing from the pod netns to the node, and its
TTL is gone. The AWS Load Balancer Controller (Stage 8) calls IMDS on
startup to learn its region and VPC ID; under hop limit 1 that call times
out and the controller crash-loops with `failed to get VPC ID ... context
deadline exceeded`. Hop limit 2 is AWS's documented fix, and doing it here
keeps `argocd/apps/aws-load-balancer-controller.yaml` free of a hardcoded
`vpcId` that would otherwise change on every rebuild.

IMDSv2 stays required (`http_tokens = "required"`). The template pins no
`image_id` or `instance_type`, so the managed node group still supplies the
EKS-optimized AMI, its bootstrap userdata, and the type from
`node_instance_types`.
