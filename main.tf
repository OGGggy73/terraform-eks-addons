module "cluster-autoscaler" {
    source = "./modules/cluster-autoscaler"
    count = var.cluster_autoscaler_enabled ? 1 : 0
    cluster_name = var.cluster_name
    cluster_identity_oidc_issuer = var.cluster_identity_oidc_issuer
    cluster_identity_oidc_issuer_arn = var.cluster_identity_oidc_issuer_arn
    helm_create_namespace = var.cluster_autoscaler_helm_create_namespace
}