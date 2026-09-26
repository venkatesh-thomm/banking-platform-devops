#!/bin/bash

echo 'Starting  apply...'

set -euo pipefail

ARGOCD_NAMESPACE="argocd"
APP_NAME="banking-backend"
AWS_REGION="us-east-1"
EKS_CLUSTER="banking-qa-eks"

echo "======================================"
echo " Banking Platform - Setup & Verification"
echo "======================================"

echo
echo "1. Configure kubectl for EKS"
aws eks update-kubeconfig \
  --region "$AWS_REGION" \
  --name "$EKS_CLUSTER"

echo
echo "2. Verify EKS nodes"
kubectl get nodes

echo
echo "3. Apply External Secrets ClusterSecretStore"
kubectl apply -f  ../k8s/external-secrets/cluster-secret-store.yaml

echo
echo "4. Apply Argo CD Application"
kubectl apply -f  ../argocd/applications/banking-backend-qa.yaml

echo
echo "5. Force Argo CD refresh"
kubectl annotate application "$APP_NAME" \
  -n "$ARGOCD_NAMESPACE" \
  argocd.argoproj.io/refresh=hard \
  --overwrite

echo
echo "6. Helm version"
helm version

echo
echo "7. Helm releases"
helm list -A

# echo
# echo "8. Argo CD applications"
# argocd app list

# echo
# echo "9. Banking Backend Argo CD application"
# argocd app get "$APP_NAME"

echo
echo "10. Kubernetes pods"
kubectl get pods -A

echo
echo "11. Banking Backend resources"
kubectl get pods -n default
kubectl get svc -n default
kubectl get ingress -n default

echo
echo "12. HPA"
kubectl get hpa -n default

echo
echo "13. Metrics"
kubectl top nodes
kubectl top pods -n default

echo
echo "14. External Secrets"
kubectl get pods -n external-secrets
kubectl get clustersecretstore

echo
echo "15. Verify deployed image"
kubectl get deployment banking-backend \
  -n default \
  -o jsonpath="{.spec.template.spec.containers[0].image}"

echo
echo

echo "16. Verify Argo CD values file"
kubectl get application "$APP_NAME" \
  -n "$ARGOCD_NAMESPACE" \
  -o jsonpath="{.spec.source.helm.valueFiles}"

echo
echo

echo "======================================"
echo " Verification Complete"
echo "======================================"

