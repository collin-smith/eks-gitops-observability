# terraform/modules/karpenter

The AWS-side prerequisites for running [Karpenter](https://karpenter.sh) on
this cluster. Karpenter itself (the controller and the `NodePool` /
`EC2NodeClass` resources) is deployed separately, via ArgoCD — see
`argocd/apps/karpenter*.yaml`. Added in **Stage 7 (Autoscaling)**.

## What it creates

- **Controller IAM role** (IRSA) — assumed by the Karpenter pod's
  ServiceAccount. Its inline policy mirrors the upstream Karpenter
  CloudFormation template for v1.x: every mutating EC2 call is tag-scoped to
  this cluster and a `karpenter.sh/nodepool`, reads are region-locked, and
  `iam:PassRole` is granted on exactly one role (below).
- **SQS interruption queue** + **EventBridge rules** — EC2 spot-interruption,
  rebalance, instance state-change and health events fan into the queue;
  Karpenter drains the affected node ahead of the 2-minute warning.
- **`karpenter.sh/discovery` tags** on the private subnets and the
  EKS-managed cluster security group, so the `EC2NodeClass` selects them by
  tag instead of by hardcoded ID.

## What it deliberately does NOT create

- **A node IAM role / instance profile.** Karpenter-launched nodes reuse the
  managed node group's role (`module.eks.node_group_role_name`) — it already
  carries the worker + CNI + ECR policies. Karpenter v1 creates and manages
  the instance profile itself (the controller policy allows it).

## Wiring

`terraform output` exposes what the ArgoCD Karpenter release needs:

| Output                          | Helm value |
|---------------------------------|------------|
| `karpenter_controller_role_arn` | `serviceAccount.annotations."eks.amazonaws.com/role-arn"` |
| `karpenter_interruption_queue`  | `settings.interruptionQueue` |
| `karpenter_node_role_name`      | `EC2NodeClass.spec.role` |

## Version note

The controller policy tracks Karpenter **v1.x**. If you pin a different
chart version in `argocd/apps/karpenter.yaml`, diff this policy against that
release's `cloudformation.yaml` before applying.
