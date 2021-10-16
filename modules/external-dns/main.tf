data "aws_region" "current" {}

# Policy
data "aws_iam_policy_document" "external_dns" {

  statement {
    sid = "ChangeResourceRecordSets"

    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = [for id in var.policy_allowed_zone_ids : "arn:aws:route53:::hostedzone/${id}"]

    effect = "Allow"
  }

  statement {
    sid = "ListResourceRecordSets"

    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource",
    ]

    resources = [
      "*",
    ]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "external_dns" {
  depends_on  = [var.mod_dependency]
  name        = "${var.cluster_name}-external-dns"
  path        = "/"
  description = "Policy for external-dns service"

  policy = data.aws_iam_policy_document.external_dns.json
}

# Role
data "aws_iam_policy_document" "external_dns_assume" {

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
        "system:serviceaccount:${var.namespace}:${var.service_account_name}",
      ]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "external_dns" {
  depends_on         = [var.mod_dependency]
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume.json
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  depends_on = [var.mod_dependency]
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

#Namespace
resource "kubernetes_namespace" "external_dns" {
  depends_on = [var.mod_dependency]
  count      = (var.create_namespace && var.namespace != "kube-system") ? 1 : 0

  metadata {
    name = var.namespace
  }
}

#Helm
resource "helm_release" "external_dns" {
  depends_on = [var.mod_dependency, kubernetes_namespace.external_dns]
  chart      = var.helm_chart_name
  namespace  = var.namespace
  name       = var.helm_release_name
  version    = var.helm_chart_version
  repository = var.helm_repo_url

  set {
    name  = "aws.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = var.service_account_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns.arn
  }

  values = [
    yamlencode(var.settings)
  ]
}