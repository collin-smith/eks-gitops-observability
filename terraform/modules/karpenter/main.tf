data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

locals {
  partition = data.aws_partition.current.partition
  region    = data.aws_region.current.region
  account   = data.aws_caller_identity.current.account_id

  # Karpenter's controller policy is scoped to resources tagged as belonging
  # to this cluster. Both the "classic" and the newer eks:eks-cluster-name
  # tag keys are checked, matching the upstream CloudFormation template.
  cluster_tag_key = "kubernetes.io/cluster/${var.cluster_name}"
  oidc_sub        = "${replace(var.oidc_provider_url, "https://", "")}:sub"
  oidc_aud        = "${replace(var.oidc_provider_url, "https://", "")}:aud"
}

# --------------------------------------------------------------------------
# Interruption queue: EC2 sends spot-interruption / rebalance / health events
# here via EventBridge, and Karpenter drains the affected node before the
# 2-minute warning runs out instead of letting the pod get hard-killed.
# --------------------------------------------------------------------------
resource "aws_sqs_queue" "interruption" {
  name                      = "${var.cluster_name}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true

  tags = var.tags
}

data "aws_iam_policy_document" "interruption_queue" {
  statement {
    sid       = "EventBridgeToSQS"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.interruption.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
  }

  statement {
    sid       = "DenyNonSecureTransport"
    effect    = "Deny"
    actions   = ["sqs:*"]
    resources = [aws_sqs_queue.interruption.arn]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.url
  policy    = data.aws_iam_policy_document.interruption_queue.json
}

# One rule per event type Karpenter reacts to; all fan into the same queue.
locals {
  interruption_rules = {
    spot_interruption = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Spot Instance Interruption Warning"]
    }
    rebalance = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Instance Rebalance Recommendation"]
    }
    instance_state_change = {
      source      = ["aws.ec2"]
      detail_type = ["EC2 Instance State-change Notification"]
    }
    scheduled_change = {
      source      = ["aws.health"]
      detail_type = ["AWS Health Event"]
    }
  }
}

resource "aws_cloudwatch_event_rule" "interruption" {
  for_each = local.interruption_rules

  name = "${var.cluster_name}-karpenter-${replace(each.key, "_", "-")}"
  event_pattern = jsonencode({
    source      = each.value.source
    detail-type = each.value.detail_type
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "interruption" {
  for_each = local.interruption_rules

  rule      = aws_cloudwatch_event_rule.interruption[each.key].name
  target_id = "KarpenterInterruptionQueue"
  arn       = aws_sqs_queue.interruption.arn
}

# --------------------------------------------------------------------------
# Controller IRSA role: the Karpenter pod assumes this via its ServiceAccount.
# --------------------------------------------------------------------------
data "aws_iam_policy_document" "controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = local.oidc_sub
      values   = ["system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = local.oidc_aud
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "controller" {
  name               = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.controller_assume_role.json

  tags = var.tags
}

# Mirrors the upstream Karpenter CloudFormation controller policy (v1.x).
# Every mutating EC2 statement is tag-scoped to this cluster + a karpenter.sh
# nodepool; read actions are region-locked. If you pin a different Karpenter
# version, diff this against that release's cloudformation.yaml.
resource "aws_iam_role_policy" "controller" {
  name = "KarpenterController"
  role = aws_iam_role.controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowScopedEC2InstanceAccessActions"
        Effect = "Allow"
        Resource = [
          "arn:${local.partition}:ec2:${local.region}::image/*",
          "arn:${local.partition}:ec2:${local.region}::snapshot/*",
          "arn:${local.partition}:ec2:${local.region}:*:security-group/*",
          "arn:${local.partition}:ec2:${local.region}:*:subnet/*",
          "arn:${local.partition}:ec2:${local.region}:*:capacity-reservation/*",
        ]
        Action = ["ec2:RunInstances", "ec2:CreateFleet"]
      },
      {
        Sid      = "AllowScopedEC2LaunchTemplateAccessActions"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:ec2:${local.region}:*:launch-template/*"
        Action   = ["ec2:RunInstances", "ec2:CreateFleet"]
        Condition = {
          StringEquals = { "aws:ResourceTag/${local.cluster_tag_key}" = "owned" }
          StringLike   = { "aws:ResourceTag/karpenter.sh/nodepool" = "*" }
        }
      },
      {
        Sid    = "AllowScopedEC2InstanceActionsWithTags"
        Effect = "Allow"
        Resource = [
          "arn:${local.partition}:ec2:${local.region}:*:fleet/*",
          "arn:${local.partition}:ec2:${local.region}:*:instance/*",
          "arn:${local.partition}:ec2:${local.region}:*:volume/*",
          "arn:${local.partition}:ec2:${local.region}:*:network-interface/*",
          "arn:${local.partition}:ec2:${local.region}:*:launch-template/*",
          "arn:${local.partition}:ec2:${local.region}:*:spot-instances-request/*",
        ]
        Action = ["ec2:RunInstances", "ec2:CreateFleet", "ec2:CreateLaunchTemplate"]
        Condition = {
          StringEquals = {
            "aws:RequestTag/${local.cluster_tag_key}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"     = var.cluster_name
          }
          StringLike = { "aws:RequestTag/karpenter.sh/nodepool" = "*" }
        }
      },
      {
        Sid    = "AllowScopedResourceCreationTagging"
        Effect = "Allow"
        Resource = [
          "arn:${local.partition}:ec2:${local.region}:*:fleet/*",
          "arn:${local.partition}:ec2:${local.region}:*:instance/*",
          "arn:${local.partition}:ec2:${local.region}:*:volume/*",
          "arn:${local.partition}:ec2:${local.region}:*:network-interface/*",
          "arn:${local.partition}:ec2:${local.region}:*:launch-template/*",
          "arn:${local.partition}:ec2:${local.region}:*:spot-instances-request/*",
        ]
        Action = "ec2:CreateTags"
        Condition = {
          StringEquals = {
            "aws:RequestTag/${local.cluster_tag_key}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name"     = var.cluster_name
            "ec2:CreateAction"                        = ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
          }
          StringLike = { "aws:RequestTag/karpenter.sh/nodepool" = "*" }
        }
      },
      {
        Sid      = "AllowScopedResourceTagging"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:ec2:${local.region}:*:instance/*"
        Action   = "ec2:CreateTags"
        Condition = {
          StringEquals = { "aws:ResourceTag/${local.cluster_tag_key}" = "owned" }
          StringLike   = { "aws:ResourceTag/karpenter.sh/nodepool" = "*" }
          "ForAllValues:StringEquals" = {
            "aws:TagKeys" = ["karpenter.sh/nodeclaim", "Name"]
          }
        }
      },
      {
        Sid    = "AllowScopedDeletion"
        Effect = "Allow"
        Resource = [
          "arn:${local.partition}:ec2:${local.region}:*:instance/*",
          "arn:${local.partition}:ec2:${local.region}:*:launch-template/*",
        ]
        Action = ["ec2:TerminateInstances", "ec2:DeleteLaunchTemplate"]
        Condition = {
          StringEquals = { "aws:ResourceTag/${local.cluster_tag_key}" = "owned" }
          StringLike   = { "aws:ResourceTag/karpenter.sh/nodepool" = "*" }
        }
      },
      {
        Sid      = "AllowRegionalReadActions"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
        ]
        Condition = {
          StringEquals = { "aws:RequestedRegion" = local.region }
        }
      },
      {
        Sid      = "AllowSSMReadActions"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:ssm:${local.region}::parameter/aws/service/*"
        Action   = "ssm:GetParameter"
      },
      {
        Sid      = "AllowPricingReadActions"
        Effect   = "Allow"
        Resource = "*"
        Action   = "pricing:GetProducts"
      },
      {
        Sid      = "AllowInterruptionQueueActions"
        Effect   = "Allow"
        Resource = aws_sqs_queue.interruption.arn
        Action   = ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:ReceiveMessage"]
      },
      {
        Sid      = "AllowPassingInstanceRole"
        Effect   = "Allow"
        Resource = var.node_iam_role_arn
        Action   = "iam:PassRole"
        Condition = {
          StringEquals = { "iam:PassedToService" = "ec2.amazonaws.com" }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:iam::${local.account}:instance-profile/*"
        Action   = ["iam:CreateInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:RequestTag/${local.cluster_tag_key}"      = "owned"
            "aws:RequestTag/eks:eks-cluster-name"          = var.cluster_name
            "aws:RequestTag/topology.kubernetes.io/region" = local.region
          }
          StringLike = { "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*" }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:iam::${local.account}:instance-profile/*"
        Action   = ["iam:TagInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${local.cluster_tag_key}"      = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region" = local.region
            "aws:RequestTag/${local.cluster_tag_key}"       = "owned"
            "aws:RequestTag/eks:eks-cluster-name"           = var.cluster_name
            "aws:RequestTag/topology.kubernetes.io/region"  = local.region
          }
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileActions"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:iam::${local.account}:instance-profile/*"
        Action   = ["iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile", "iam:DeleteInstanceProfile"]
        Condition = {
          StringEquals = {
            "aws:ResourceTag/${local.cluster_tag_key}"      = "owned"
            "aws:ResourceTag/topology.kubernetes.io/region" = local.region
          }
          StringLike = { "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*" }
        }
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:iam::${local.account}:instance-profile/*"
        Action   = "iam:GetInstanceProfile"
      },
      {
        Sid      = "AllowAPIServerEndpointDiscovery"
        Effect   = "Allow"
        Resource = "arn:${local.partition}:eks:${local.region}:${local.account}:cluster/${var.cluster_name}"
        Action   = "eks:DescribeCluster"
      },
    ]
  })
}

# --------------------------------------------------------------------------
# Discovery tags: the EC2NodeClass selects subnets and the security group by
# this tag rather than by hardcoded IDs.
# --------------------------------------------------------------------------
resource "aws_ec2_tag" "subnet_discovery" {
  for_each = toset(var.discovery_subnet_ids)

  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "cluster_sg_discovery" {
  resource_id = var.cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
