data "aws_region" "current" {}

module "cluster-autoscaler" {
    source = "./modules/cluster-autoscaler"
    count = var.cluster_autoscaler_enabled ? 1 : 0
    cluster_name = var.cluster_name
    cluster_identity_oidc_issuer = var.cluster_identity_oidc_issuer
    cluster_identity_oidc_issuer_arn = var.cluster_identity_oidc_issuer_arn
    helm_create_namespace = var.cluster_autoscaler_helm_create_namespace
}

module "metrics-server" {
    source = "./modules/metrics-server"
    count = var.metrics_server_enabled ? 1 : 0
}

module "ingress-nginx" {
    source = "./modules/ingress-nginx"
    count = var.ingress_nginx_enabled ? 1 : 0
    additional_set = var.ingress_nginx_additional_sets
}

module "external-secrets" {
    source = "./modules/external-secrets"
    count = var.external_secrets_enabled ? 1 : 0
    cluster_name                     = var.cluster_name
    cluster_identity_oidc_issuer     = var.cluster_identity_oidc_issuer
    cluster_identity_oidc_issuer_arn = var.cluster_identity_oidc_issuer_arn
    secrets_aws_region               = data.aws_region.current.name
}

module "external-dns" {
    source = "./modules/external-dns"
    count = var.external_dns_enabled ? 1 : 0
    cluster_name                     = var.cluster_name
    cluster_identity_oidc_issuer     = var.cluster_identity_oidc_issuer
    cluster_identity_oidc_issuer_arn = var.cluster_identity_oidc_issuer_arn
    settings = {
    "policy" = "sync" # Modify how DNS records are sychronized between sources and providers.
    }
    mod_dependency                   = var.hosted_zones
    policy_allowed_zone_ids          = var.hosted_zone_ids
}