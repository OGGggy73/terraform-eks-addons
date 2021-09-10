

module "cluster-autoscaler" {
    source = "./modules/cluster-autoscaler"
    enabled = var.enabled
    cluster_name = var.cluster_name
    cluster_identity_oidc_issuer = var.cluster_identity_oidc_issuer
    cluster_identity_oidc_issuer_arn = var.cluster_identity_oidc_issuer_arn
    helm_create_namespace = var.helm_create_namespace
}