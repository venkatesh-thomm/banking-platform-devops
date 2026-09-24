resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.chart_version

  set = [
    {
      name  = "server.service.type"
      value = "ClusterIP"
    }
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}
