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
- **`karpenter.sh/discovery` tag** on the EKS-managed cluster security
  group, so the `EC2NodeClass` selects it by tag instead of a hardcoded ID.
  (The matching tag on the private subnets is set in the `vpc` module,
  next to their other `kubernetes.io/*` tags — putting it there avoids an
  `aws_ec2_tag` vs `aws_subnet.tags` reconciliation fight.)

## What it deliberately does NOT create

- **A node IAM role / instance profile.** Karpenter-launched nodes reuse the
  managed node group's role (`module.eks.node_group_role_name`) — it already
  carries the worker + CNI + ECR policies. Karpenter v1 creates and manages
  the instance profile itself (the controller policy allows it).

- **The EC2 Spot service-linked role.** `AWSServiceRoleForEC2Spot` is
  account-global, not per-environment, so it's a prerequisite rather than a
  module resource. On an account that has never launched a Spot instance,
  Karpenter's first spot `CreateFleet` fails with
  `AuthFailure.ServiceLinkedRoleCreationNotPermitted` and it silently falls
  back to on-demand. Create it once per account:

  ```
  aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
  ```

## Wiring

`terraform output` exposes what the ArgoCD Karpenter release needs:

| Output                          | Helm value |
|---------------------------------|------------|
| `karpenter_controller_role_arn` | `serviceAccount.annotations."eks.amazonaws.com/role-arn"` |
| `karpenter_interruption_queue`  | `settings.interruptionQueue` |
| `karpenter_node_role_name`      | `EC2NodeClass.spec.role` |

## Version note

The controller policy is transcribed from Karpenter **v1.14.1**'s
`cloudformation.yaml` (matching the chart version pinned in
`argocd/apps/karpenter.yaml`). If you bump that pin, diff this policy
against the new release's `cloudformation.yaml` — statements get added
between minor versions (v1.14 added `AllowUnscopedInstanceProfileListAction`
and `AllowZonalShiftStatusReadOnly`, among others).
