variable "cluster_name" {
  type        = string
  description = "Name of EKS cluster. Used to fetch authentication details."
}

variable "flux_git_branch" {
  type        = string
  default     = "stable"
  description = "flux git branch name"
}

variable "flux_git_email" {
  type        = string
  default     = "flux@localhost"
  description = "flux git email"
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

variable "flux_ssh_known_hosts" {
  type        = string
  default     = ""
  description = "SSH known hosts used to access private helm repos via git SSH. See https://github.com/fluxcd/helm-operator/blob/master/chart/helm-operator/README.md#use-a-private-git-server"
}

variable "flux_deploy_image_automation" {
  type        = bool
  default     = false
  description = "Optionally deploy the image automation controller with the gitops toolkit"
}