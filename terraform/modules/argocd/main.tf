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


resource "kubernetes_manifest" "banking_backend" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "banking-backend-qa"
      namespace = var.namespace
    }

    spec = {
      project = "default"

      source = {
        repoURL        = "https://github.com/venkatesh-thomm/banking-platform-devops.git"
        targetRevision = "dev"
        path           = "helm/banking-backend"

        helm = {
          valueFiles = [
            "values-qa.yaml"
          ]
        }
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }

      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }

        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  }

  depends_on = [
    helm_release.argocd
  ]
}
