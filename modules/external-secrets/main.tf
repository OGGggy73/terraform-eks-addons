# Policy
data "aws_iam_policy_document" "kubernetes_external_secrets" {

  statement {
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "ssm:GetParameter"
    ]
    resources = [
      "*",
    ]
    effect = "Allow"
  }

}

resource "aws_iam_policy" "kubernetes_external_secrets" {
  depends_on  = [var.mod_dependency]
  name        = "${var.cluster_name}-external-secrets"
  path        = "/"
  description = "Policy for external secrets service"

  policy = data.aws_iam_policy_document.kubernetes_external_secrets.json
}

# Role
data "aws_iam_policy_document" "kubernetes_external_secrets_assume" {

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

resource "aws_iam_role" "kubernetes_external_secrets" {
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.kubernetes_external_secrets_assume.json
}

resource "aws_iam_role_policy_attachment" "kubernetes_external_secrets" {
  role       = aws_iam_role.kubernetes_external_secrets.name
  policy_arn = aws_iam_policy.kubernetes_external_secrets.arn
}

#Namespace
resource "kubernetes_namespace" "kubernetes_external_secrets" {
  depends_on = [var.mod_dependency]
  count      = (var.create_namespace && var.namespace != "kube-system") ? 1 : 0

  metadata {
    name = var.namespace
  }
}

#Helm
resource "helm_release" "kubernetes_external_secrets" {
  depends_on = [var.mod_dependency, kubernetes_namespace.kubernetes_external_secrets]
  name       = var.helm_chart_name
  chart      = var.helm_chart_release_name
  repository = var.helm_chart_repo
  version    = var.helm_chart_version
  namespace  = var.namespace

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "env.AWS_REGION"
    value = var.secrets_aws_region
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
    value = aws_iam_role.kubernetes_external_secrets.arn
  }

  set {
    name  = "securityContext.fsGroup"
    value = 65534
  }

  set {
    name  = "customResourceManagerDisabled"
    value = true
  }

  values = [
    yamlencode(var.settings)
  ]

}