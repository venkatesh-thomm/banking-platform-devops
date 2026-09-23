resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"

  version = var.chart_version

  set = [
    {
      name  = "args"
      value = "{--kubelet-preferred-address-types=InternalIP}"
    }
  ]
}
