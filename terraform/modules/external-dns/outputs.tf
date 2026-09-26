output "role_arn" {
  value = aws_iam_role.external_dns.arn
}

output "namespace" {
  value = kubernetes_namespace.external_dns.metadata[0].name
}
