variable "cluster_autoscaler_enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled"
}

variable "metrics_server_enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled"
}

variable "ingress_nginx_enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled"
}

variable "external_secrets_enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled"
}

variable "external_dns_enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled"
}

variable "ingress_nginx_additional_sets" {
  type        = list
  default     = []
  description = "Variable containing additional values passed to helm chart"
}

variable "flux_enabled" {
  type        = bool
  default     = true
  description = "Variable indicating whether deployment is enabled"
}

variable "cluster_name" {
  type        = string
  description = "The name of the cluster"
}

variable "cluster_identity_oidc_issuer" {
  type        = string
  description = "The OIDC Identity issuer for the cluster"
}

variable "cluster_identity_oidc_issuer_arn" {
  type        = string
  description = "The OIDC Identity issuer ARN for the cluster that can be used to associate IAM roles with a service account"
}

variable "cluster_autoscaler_helm_create_namespace" {
  type        = bool
  default     = true
  description = "Create the namespace if it does not yet exist"
}

variable "hosted_zones" {
  type        = list
  default     = []
  description = "List of Hosted Zones to be depended on for creation"
}

variable "hosted_zone_ids" {
  type        = list
  default     = []
  description = "List of Hosted Zones to be allowed access to externalDNS"
}

variable "flux_git_branch" {
  type        = string
  description = "flux git branch name"
}

variable "flux_git_url" {
  type        = string
  description = "flux git url"
}

variable "flux_git_path" {
  type        = string
  default     = ""
  description = "Path within git repo to locate Kubernetes manifests (relative path)"
}

variable "flux_sync_interval" {
  type        = string
  default     = "5m"
  description = "Flux sync interval"
}