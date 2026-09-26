
python verify-deployment-banking.py

ENV=qa python verify-deployment-banking.py


Python script
     |
     v
Check kubectl connectivity
     |
     v
Check Banking Backend Deployment
     |
     v
Check Pods + Readiness
     |
     v
Check Argo CD
     |
     v
Check ExternalSecret
     |
     v
Check Service
     |
     v
Check ALB / Ingress
     |
     v
Call /health
     |
     v
Final PASS / FAIL