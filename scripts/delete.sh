#!/bin/bash

set -euo pipefail

ARGOCD_NAMESPACE="argocd"
APP_NAME="banking-backend"

echo "======================================"
echo " Banking Platform - Destroy"
echo "======================================"

echo
echo "1. Delete Banking Backend Argo CD Application"
kubectl delete \
  -f ../argocd/applications/banking-backend-qa.yaml \
  --ignore-not-found

echo
echo "2. Delete External Secrets ClusterSecretStore"
kubectl delete \
  -f ../k8s/external-secrets/cluster-secret-store.yaml \
  --ignore-not-found

echo


echo
echo "======================================"
echo " Banking Platform - Destroy Complete"
echo "======================================"