#!/bin/bash

set -euo pipefail

echo "======================================"
echo " Banking Platform - Destroy"
echo "======================================"
echo

# --------------------------------------------------
# 1. Delete Banking Backend Argo CD Application
# --------------------------------------------------

echo "1. Deleting Banking Backend Argo CD Application..."

kubectl delete \
  -f ../argocd/applications/banking-backend-qa.yaml \
  --ignore-not-found=true

echo "Banking Backend Argo CD Application deleted."

echo "======================================="


# --------------------------------------------------
# 2. Delete External Secrets ClusterSecretStore & Secret
# --------------------------------------------------

echo "2. Deleting External Secrets ClusterSecretStore & Secret..."

kubectl delete \
  -f ../k8s/external-secrets/cluster-secret-store.yaml \
  --ignore-not-found=true


kubectl delete \
  -f ../k8s/external-secrets/banking-db-secret.yaml \
  --ignore-not-found=true

echo "ClusterSecretStore and Secret deleted."

echo "======================================="


#--------------------------------------------------
# 3. Destroy Terraform Addons & Infrastructure
#--------------------------------------------------

echo "3. Destroying Terraform Addons..."

cd ../terraform/environments/qa/addons

terraform destroy -auto-approve

echo "Destroying Terraform Addons complete."

echo "======================================="


#--------------------------------------------------
# 4. Destroy Terraform Infrastructure
#--------------------------------------------------

echo "4. Destroying Terraform Infrastructure..."

cd ../infrastructure
terraform destroy -auto-approve

echo "4. Destroying Terraform Infrastructure complete."

echo "======================================="


# --------------------------------------------------
# 4. Verification
# --------------------------------------------------

echo "4. Verifying remaining Helm releases..."

helm list -A || true

echo
echo "Checking remaining Kubernetes namespaces..."

kubectl get namespaces || true

echo
echo "Checking remaining Kubernetes resources..."

kubectl get pods -A || true

echo
echo "======================================"
echo " Banking Platform - Destroy Complete"
echo "======================================"


