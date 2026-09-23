#!/usr/bin/env bash

set -euo pipefail

ARGOCD_NAMESPACE="argocd"
APP_NAME="banking-backend-qa"

echo "======================================"
echo " Banking Platform - Helm & ArgoCD"
echo "======================================"

echo
echo "1. Helm version"
helm version

echo
echo "2. Helm repositories"
helm repo list

echo
echo "3. Update Helm repositories"
helm repo update

echo
echo "4. Helm releases"
helm list -A

echo
echo "5. Metrics Server Helm release"
helm list -n kube-system | grep metrics-server || true

echo
echo "6. Argo CD Helm release"
helm list -n "$ARGOCD_NAMESPACE"

echo
echo "7. Argo CD applications"
argocd app list

echo
echo "8. Banking Backend Argo CD application"
argocd app get "$APP_NAME"

echo
echo "9. Kubernetes resources"
kubectl get pods -A

echo
echo "10. HPA"
kubectl get hpa -n default

echo
echo "11. Metrics"
kubectl top nodes
kubectl top pods -n default

echo
echo "======================================"
echo " Verification Complete"
echo "======================================"