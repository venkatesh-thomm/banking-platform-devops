variable "namespace" {
  type        = string
  description = "Kubernetes namespace for Argo CD"
  default     = "argocd"
}

variable "chart_version" {
  type        = string
  description = "Argo CD Helm chart version"
  default     = "9.1.2"
}
