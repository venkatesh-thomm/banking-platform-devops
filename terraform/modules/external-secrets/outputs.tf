
output "namespace" {
  value = kubernetes_namespace.external_secrets.metadata[0].name
}

output "service_account" {
  value = "external-secrets"
}
