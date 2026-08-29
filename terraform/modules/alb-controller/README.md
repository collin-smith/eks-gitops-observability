# terraform/modules/alb-controller

The AWS-side prerequisite for running the [AWS Load Balancer
Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
on this cluster. The controller itself is deployed separately, via ArgoCD —
see `argocd/apps/aws-load-balancer-controller.yaml`. Added in **Stage 8
(Ingress)**.

## What it creates

- **Controller IAM role** (IRSA) — assumed by the
  `aws-load-balancer-controller` pod's ServiceAccount in `kube-system`. Its
  inline policy is transcribed verbatim from the controller's
  `docs/install/iam_policy.json` at tag **v3.5.0** (the appVersion of the
  pinned chart). Every mutating `elasticloadbalancing` / security-group call
  is gated on the `elbv2.k8s.aws/cluster` tag the controller stamps on the
  resources it owns, so the role can only touch load balancers and target
  groups that belong to a cluster it manages.

## What it deliberately does NOT create

- **Subnets or subnet tags.** The controller discovers where to place an
  internet-facing ALB by looking for the `kubernetes.io/role/elb=1` tag —
  already set on the public subnets in the `vpc` module, next to their other
  `kubernetes.io/*` tags. Private subnets carry `kubernetes.io/role/internal-elb=1`
  for internal load balancers.
- **The IngressClass.** The Helm chart creates the `alb` IngressClass and
  its `IngressClassParams` CRD instance (`createIngressClassResource: true`,
  the chart default). The demo-app chart's Ingress template references it by
  `ingressClassName: alb`.
- **The `elasticloadbalancing` service-linked role.** `iam:CreateServiceLinkedRole`
  is in the policy (scoped to `elasticloadbalancing.amazonaws.com`), so the
  controller creates `AWSServiceRoleForElasticLoadBalancing` itself on first
  use if the account doesn't already have it.

## Wiring

`terraform output` exposes what the ArgoCD release needs:

| Output                 | Helm value |
|------------------------|------------|
| `alb_controller_role_arn` | `serviceAccount.annotations."eks.amazonaws.com/role-arn"` |

`clusterName` in the chart values is the literal cluster name
(`eks-gitops-observability-dev`), same as the other in-repo Application
manifests.

## Version note

The controller policy matches chart **3.5.0 / appVersion v3.5.0**, pinned in
`argocd/apps/aws-load-balancer-controller.yaml`. The chart version scheme
changed at v3.0.0 — controller v2.x used chart 1.x, v3.x uses a matching
chart 3.x. On any bump, diff this policy against
`docs/install/iam_policy.json` at the new release's git tag.
