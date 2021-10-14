locals {
  helm_chart            = "ingress-nginx"
  helm_repository       = "https://kubernetes.github.io/ingress-nginx"
  helm_template_version = "3.36.0"

  loadBalancerIP = var.ip_address == null ? [] : [
    {
      name  = "controller.service.loadBalancerIP"
      value = var.ip_address
    }
  ]

  metrics_enabled = var.metrics_enabled ? [
    {
      name  = "controller.metrics.enabled"
      value = "true"
    },
    {
      name  = "controller.metrics.serviceMonitor.enabled"
      value = "true"
    },
    {
      name  = "controller.metrics.serviceMonitor.additionalLabels.release"
      value = "kube-prometheus-stack"
    }
  ] : []

  controller_service_nodePorts = var.define_nodePorts ? [
    {
      name  = "controller.service.nodePorts.http"
      value = var.service_nodePort_http
    },
    {
      name  = "controller.service.nodePorts.https"
      value = var.service_nodePort_https
    }
  ] : []
}

resource "helm_release" "application" {
  name       = var.name
  chart      = local.helm_chart
  namespace  = var.namespace
  repository = local.helm_repository
  version    = local.helm_template_version

  wait = "false"

  values = [var.disable_heavyweight_metrics ? file("${path.module}/templates/metrics-disable.yaml") : ""]

  set {
    name  = "controller.kind"
    value = var.controller_kind
  }
  set {
    name  = "controller.daemonset.useHostPort"
    value = var.controller_daemonset_useHostPort
  }
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = var.controller_service_externalTrafficPolicy
  }
  set {
    name  = "controller.publishService.enabled"
    value = var.publish_service
  }
  set {
    name  = "controller.resources.requests.memory"
    type  = "string"
    value = "${var.controller_request_memory}Mi"
  }

  dynamic "set" {
    for_each = local.controller_service_nodePorts
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  dynamic "set" {
    for_each = local.loadBalancerIP
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  dynamic "set" {
    for_each = local.metrics_enabled
    content {
      name  = set.value.name
      value = set.value.value
    }
  }

  dynamic "set" {
    for_each = var.additional_set
    content {
      name  = set.value.name
      value = set.value.value
      type  = lookup(set.value, "type", null)
    }
  }
}