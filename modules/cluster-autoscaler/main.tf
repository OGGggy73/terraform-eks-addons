locals {
  k8s_irsa_role_create = var.k8s_rbac_create && var.k8s_service_account_create && var.k8s_irsa_role_create

  values = yamlencode({
    "awsRegion" : data.aws_region.current.name,
    "autoDiscovery" : {
      "clusterName" : var.cluster_name
    },
    "rbac" : {
      "create" : var.k8s_rbac_create,
      "serviceAccount" : {
        "create" : var.k8s_service_account_create,
        "name" : var.k8s_service_account_name
        "annotations" : {
          "eks.amazonaws.com/role-arn" : local.k8s_irsa_role_create ? aws_iam_role.cluster_autoscaler[0].arn : ""
        }
      }
    }
  })
}

data "aws_region" "current" {}

data "utils_deep_merge_yaml" "values" {
  input = compact([
    local.values,
    var.values
  ])
}

resource "helm_release" "cluster_autoscaler" {
  chart            = var.helm_chart_name
  create_namespace = var.helm_create_namespace
  namespace        = var.k8s_namespace
  name             = var.helm_release_name
  version          = var.helm_chart_version
  repository       = var.helm_repo_url

  values = [
    data.utils_deep_merge_yaml.values.output
  ]

  dynamic "set" {
    for_each = var.settings
    content {
      name  = set.key
      value = set.value
    }
  }
}

data "aws_iam_policy_document" "cluster_autoscaler" {
  count = local.k8s_irsa_role_create ? 1 : 0

  statement {
    sid = "Autoscaling"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    resources = [
      "*",
    ]

    effect = "Allow"
  }

}

resource "aws_iam_policy" "cluster_autoscaler" {
  count       = local.k8s_irsa_role_create ? 1 : 0
  name        = "${var.cluster_name}-cluster-autoscaler"
  path        = "/"
  description = "Policy for cluster-autoscaler service"

  policy = data.aws_iam_policy_document.cluster_autoscaler[0].json
}

data "aws_iam_policy_document" "cluster_autoscaler_assume" {
  count = local.k8s_irsa_role_create ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.cluster_identity_oidc_issuer_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_identity_oidc_issuer, "https://", "")}:sub"

      values = [
        "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count              = local.k8s_irsa_role_create ? 1 : 0
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume[0].json
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count      = local.k8s_irsa_role_create ? 1 : 0
  role       = aws_iam_role.cluster_autoscaler[0].name
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
}