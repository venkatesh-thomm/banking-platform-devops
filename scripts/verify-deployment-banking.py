#!/usr/bin/env python3
# =============================================================================
# Banking Platform - Deployment Verification
#
# Verifies the actual banking-backend Helm deployment:
#
#   1. Kubernetes connectivity
#   2. banking-backend Deployment
#   3. Deployment rollout / replica readiness
#   4. banking-backend Pods
#   5. Argo CD Application
#   6. ExternalSecret: banking-db-secret
#   7. Service
#   8. Ingress / AWS ALB
#   9. HTTP /health endpoint
#
# Based on:
#   helm/banking-backend
#
# Default environment:
#   qa
#
# Usage:
#   python verify-deployment.py
#
# PowerShell:
#   $env:ENV="qa"
#   python verify-deployment.py
#
# Linux/macOS/Git Bash:
#   ENV=qa python verify-deployment.py
#
# Optional:
#   ENV=qa
#   NAMESPACE=qa
#   ARGOCD_APP_NAME=banking-backend-qa
#   TIMEOUT=300
# =============================================================================

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime


# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

ENV = os.environ.get("ENV", "qa")
NAMESPACE = os.environ.get("NAMESPACE", ENV)

APP_NAME = "banking-backend"
ARGOCD_NAMESPACE = "argocd"
ARGOCD_APP_NAME = os.environ.get(
    "ARGOCD_APP_NAME",
    f"{APP_NAME}-{ENV}",
)

EXTERNAL_SECRET_NAME = "banking-db-secret"

TIMEOUT = int(os.environ.get("TIMEOUT", "300"))

# Confirmed from Helm deployment.yaml
HEALTH_PATH = "/health"
CONTAINER_PORT = 8000


# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
BLUE = "\033[0;34m"
CYAN = "\033[0;36m"
NC = "\033[0m"

ERRORS = 0


def timestamp():
    return datetime.now().strftime("%H:%M:%S")


def info(message):
    print(f"{BLUE}[{timestamp()}]     {message}{NC}")


def success(message):
    print(f"{GREEN}[{timestamp()}] OK  {message}{NC}")


def warning(message):
    print(f"{YELLOW}[{timestamp()}] !!  {message}{NC}")


def failure(message):
    global ERRORS
    ERRORS += 1
    print(f"{RED}[{timestamp()}] FAIL {message}{NC}", file=sys.stderr)


def fatal(message):
    print(f"{RED}[{timestamp()}] ERR {message}{NC}", file=sys.stderr)
    sys.exit(1)


# -----------------------------------------------------------------------------
# Command execution
# -----------------------------------------------------------------------------

def run_command(command, capture=True, allow_failure=False):
    try:
        result = subprocess.run(
            command,
            capture_output=capture,
            text=True,
        )
    except FileNotFoundError:
        if allow_failure:
            return "", 1
        fatal(f"Command not found: {command[0]}")

    if result.returncode != 0 and not allow_failure:
        stderr = result.stderr.strip() if capture else ""
        fatal(
            f"Command failed: {' '.join(command)}"
            + (f"\n{stderr}" if stderr else "")
        )

    stdout = result.stdout.strip() if capture else ""
    return stdout, result.returncode


def kubectl_json(args, allow_failure=False):
    output, rc = run_command(
        ["kubectl"] + args,
        capture=True,
        allow_failure=allow_failure,
    )

    if rc != 0 or not output:
        return None

    try:
        return json.loads(output)
    except json.JSONDecodeError:
        return None


# -----------------------------------------------------------------------------
# Verify required tools
# -----------------------------------------------------------------------------

def check_required_tools():
    for tool in ("kubectl",):
        _, rc = run_command(
            ["which", tool],
            capture=True,
            allow_failure=True,
        )

        if rc != 0:
            fatal(f"{tool} is not installed or not available in PATH.")


# -----------------------------------------------------------------------------
# Header
# -----------------------------------------------------------------------------

def print_header():
    print()
    print("============================================")
    print("  Banking Platform - Deployment Verification")
    print("============================================")
    print()
    print(f"  Environment        : {ENV}")
    print(f"  Kubernetes Namespace: {NAMESPACE}")
    print(f"  Application         : {APP_NAME}")
    print(f"  ArgoCD Application  : {ARGOCD_APP_NAME}")
    print(f"  ExternalSecret      : {EXTERNAL_SECRET_NAME}")
    print(f"  Health Endpoint     : {HEALTH_PATH}")
    print()


# -----------------------------------------------------------------------------
# Check 1 - Kubernetes connectivity
# -----------------------------------------------------------------------------

def check_kubernetes():
    print("--------------------------------------------")
    print("  Check 1: Kubernetes Connectivity")
    print("--------------------------------------------")

    _, rc = run_command(
        ["kubectl", "cluster-info"],
        capture=True,
        allow_failure=True,
    )

    if rc == 0:
        success("Kubernetes cluster is reachable.")
        return True

    failure("Cannot connect to the Kubernetes cluster.")
    print()
    print("  Check:")
    print("    kubectl config current-context")
    print("    kubectl get nodes")
    return False


# -----------------------------------------------------------------------------
# Check 2 - Deployment
# -----------------------------------------------------------------------------

def find_backend_deployment():
    """
    The Helm chart uses:
      selector:
        app: {{ include "banking-backend.fullname" . }}

    Instead of guessing the rendered fullname, discover the deployment by
    checking its container name. The actual container name in deployment.yaml
    is 'banking-backend'.
    """

    data = kubectl_json(
        ["get", "deployments", "-n", NAMESPACE, "-o", "json"],
        allow_failure=True,
    )

    if not data:
        return None

    for deployment in data.get("items", []):
        containers = deployment.get("spec", {}).get("template", {}).get(
            "spec", {}
        ).get("containers", [])

        for container in containers:
            if container.get("name") == APP_NAME:
                return deployment

    return None


def check_deployment():
    print()
    print("--------------------------------------------")
    print("  Check 2: Banking Backend Deployment")
    print("--------------------------------------------")

    deployment = find_backend_deployment()

    if not deployment:
        failure(
            f"No deployment containing container '{APP_NAME}' "
            f"was found in namespace '{NAMESPACE}'."
        )
        return None

    metadata = deployment.get("metadata", {})
    spec = deployment.get("spec", {})
    status = deployment.get("status", {})

    deployment_name = metadata.get("name")
    desired = spec.get("replicas", 0)
    ready = status.get("readyReplicas", 0)
    available = status.get("availableReplicas", 0)

    print(f"  Deployment : {deployment_name}")
    print(f"  Desired    : {desired}")
    print(f"  Ready      : {ready}")
    print(f"  Available  : {available}")
    print()

    if desired > 0 and ready == desired and available == desired:
        success(
            f"Deployment '{deployment_name}' is healthy "
            f"({ready}/{desired} Ready)."
        )
    else:
        failure(
            f"Deployment '{deployment_name}' is not fully ready: "
            f"desired={desired}, ready={ready}, available={available}"
        )

    return deployment_name


# -----------------------------------------------------------------------------
# Check 3 - Deployment rollout and Pods
# -----------------------------------------------------------------------------

def check_rollout_and_pods(deployment_name):
    print()
    print("--------------------------------------------")
    print("  Check 3: Deployment Rollout and Pods")
    print("--------------------------------------------")

    if not deployment_name:
        failure("Skipping rollout check because Deployment was not found.")
        return

    info(f"Waiting up to {TIMEOUT}s for rollout to complete...")

    _, rc = run_command(
        [
            "kubectl",
            "rollout",
            "status",
            f"deployment/{deployment_name}",
            "-n",
            NAMESPACE,
            f"--timeout={TIMEOUT}s",
        ],
        capture=True,
        allow_failure=True,
    )

    if rc == 0:
        success(f"Deployment '{deployment_name}' rollout completed.")
    else:
        failure(f"Deployment '{deployment_name}' rollout failed or timed out.")

    print()
    run_command(
        ["kubectl", "get", "pods", "-n", NAMESPACE, "-o", "wide"],
        capture=False,
        allow_failure=True,
    )

    # Get pods belonging to the actual Deployment using its selector.
    deployment = kubectl_json(
        ["get", "deployment", deployment_name, "-n", NAMESPACE, "-o", "json"],
        allow_failure=True,
    )

    if not deployment:
        return

    selector = deployment.get("spec", {}).get("selector", {}).get(
        "matchLabels", {}
    )

    if not selector:
        failure("Deployment selector could not be determined.")
        return

    selector_string = ",".join(
        f"{key}={value}" for key, value in selector.items()
    )

    pods = kubectl_json(
        [
            "get",
            "pods",
            "-n",
            NAMESPACE,
            "-l",
            selector_string,
            "-o",
            "json",
        ],
        allow_failure=True,
    )

    if not pods:
        failure("Could not retrieve Banking Backend pods.")
        return

    pod_items = pods.get("items", [])

    if not pod_items:
        failure("No Banking Backend pods were found.")
        return

    not_ready = []

    for pod in pod_items:
        pod_name = pod.get("metadata", {}).get("name", "unknown")
        phase = pod.get("status", {}).get("phase", "Unknown")

        conditions = pod.get("status", {}).get("conditions", [])

        ready_condition = next(
            (
                condition
                for condition in conditions
                if condition.get("type") == "Ready"
            ),
            None,
        )

        is_ready = (
            ready_condition is not None
            and ready_condition.get("status") == "True"
        )

        if phase != "Running" or not is_ready:
            not_ready.append(
                f"{pod_name}: phase={phase}, ready={is_ready}"
            )

    if not not_ready:
        success(f"All {len(pod_items)} Banking Backend pod(s) are Ready.")
    else:
        for pod in not_ready:
            failure(f"Pod is not Ready: {pod}")


# -----------------------------------------------------------------------------
# Check 4 - ArgoCD
# -----------------------------------------------------------------------------

def check_argocd():
    print()
    print("--------------------------------------------")
    print("  Check 4: ArgoCD Application")
    print("--------------------------------------------")

    app = kubectl_json(
        [
            "get",
            "application",
            ARGOCD_APP_NAME,
            "-n",
            ARGOCD_NAMESPACE,
            "-o",
            "json",
        ],
        allow_failure=True,
    )

    if not app:
        failure(
            f"ArgoCD Application '{ARGOCD_APP_NAME}' was not found."
        )
        return

    status = app.get("status", {})

    sync_status = status.get("sync", {}).get("status", "Unknown")
    health_status = status.get("health", {}).get("status", "Unknown")

    print(f"  Sync status   : {sync_status}")
    print(f"  Health status : {health_status}")
    print()

    if sync_status == "Synced" and health_status == "Healthy":
        success(
            f"ArgoCD Application '{ARGOCD_APP_NAME}' "
            "is Synced and Healthy."
        )
    else:
        failure(
            f"ArgoCD Application '{ARGOCD_APP_NAME}' is not healthy: "
            f"sync={sync_status}, health={health_status}"
        )


# -----------------------------------------------------------------------------
# Check 5 - ExternalSecret
# -----------------------------------------------------------------------------

def check_external_secret():
    print()
    print("--------------------------------------------")
    print("  Check 5: External Secrets")
    print("--------------------------------------------")

    secret = kubectl_json(
        [
            "get",
            "externalsecret",
            EXTERNAL_SECRET_NAME,
            "-n",
            NAMESPACE,
            "-o",
            "json",
        ],
        allow_failure=True,
    )

    if not secret:
        failure(
            f"ExternalSecret '{EXTERNAL_SECRET_NAME}' was not found "
            f"in namespace '{NAMESPACE}'."
        )
        return

    conditions = secret.get("status", {}).get("conditions", [])

    ready_condition = next(
        (
            condition
            for condition in conditions
            if condition.get("type") == "Ready"
        ),
        None,
    )

    if not ready_condition:
        failure(
            f"ExternalSecret '{EXTERNAL_SECRET_NAME}' "
            "has no Ready condition."
        )
        return

    ready_status = ready_condition.get("status")
    reason = ready_condition.get("reason", "Unknown")
    message = ready_condition.get("message", "")

    print(f"  Ready  : {ready_status}")
    print(f"  Reason : {reason}")

    if ready_status == "True":
        success(
            f"ExternalSecret '{EXTERNAL_SECRET_NAME}' is Ready."
        )
    else:
        failure(
            f"ExternalSecret '{EXTERNAL_SECRET_NAME}' is not Ready: "
            f"{message}"
        )


# -----------------------------------------------------------------------------
# Check 6 - Service
# -----------------------------------------------------------------------------

def check_service(deployment_name):
    print()
    print("--------------------------------------------")
    print("  Check 6: Kubernetes Service")
    print("--------------------------------------------")

    if not deployment_name:
        failure("Skipping Service check because Deployment was not found.")
        return

    service = kubectl_json(
        ["get", "svc", deployment_name, "-n", NAMESPACE, "-o", "json"],
        allow_failure=True,
    )

    if not service:
        failure(
            f"Service '{deployment_name}' was not found "
            f"in namespace '{NAMESPACE}'."
        )
        return

    spec = service.get("spec", {})
    ports = spec.get("ports", [])

    print(f"  Service : {deployment_name}")
    print(f"  Type    : {spec.get('type', 'Unknown')}")

    if ports:
        for port in ports:
            print(
                f"  Port    : {port.get('port')} "
                f"-> targetPort {port.get('targetPort')}"
            )

    print()

    # The Helm chart uses ClusterIP and port 8000 by default.
    if spec.get("type") == "ClusterIP":
        success(f"Service '{deployment_name}' exists.")
    else:
        warning(
            f"Service '{deployment_name}' exists but type is "
            f"{spec.get('type')}."
        )


# -----------------------------------------------------------------------------
# Check 7 - Ingress / ALB
# -----------------------------------------------------------------------------

def get_alb_hostname():
    ingresses = kubectl_json(
        ["get", "ingress", "-n", NAMESPACE, "-o", "json"],
        allow_failure=True,
    )

    if not ingresses:
        return None, None

    items = ingresses.get("items", [])

    if not items:
        return None, None

    for ingress in items:
        metadata = ingress.get("metadata", {})
        status = ingress.get("status", {})
        load_balancer = status.get("loadBalancer", {})
        ingress_status = load_balancer.get("ingress", [])

        if ingress_status:
            hostname = (
                ingress_status[0].get("hostname")
                or ingress_status[0].get("ip")
            )

            if hostname:
                return metadata.get("name"), hostname

    return items[0].get("metadata", {}).get("name"), None


def check_ingress():
    print()
    print("--------------------------------------------")
    print("  Check 7: Ingress / AWS ALB")
    print("--------------------------------------------")

    ingresses = kubectl_json(
        ["get", "ingress", "-n", NAMESPACE, "-o", "json"],
        allow_failure=True,
    )

    if not ingresses:
        warning(
            f"No Ingress resource found in namespace '{NAMESPACE}'. "
            "If ingress.enabled=false for this environment, this is expected."
        )
        return None

    items = ingresses.get("items", [])

    if not items:
        warning(
            f"No Ingress resources found in namespace '{NAMESPACE}'. "
            "If ingress.enabled=false for this environment, this is expected."
        )
        return None

    for ingress in items:
        name = ingress.get("metadata", {}).get("name", "unknown")
        status = ingress.get("status", {}).get("loadBalancer", {})
        addresses = status.get("ingress", [])

        rules = ingress.get("spec", {}).get("rules", [])

        hosts = [
            rule.get("host")
            for rule in rules
            if rule.get("host")
        ]

        print(f"  Ingress : {name}")

        if hosts:
            print(f"  Host    : {', '.join(hosts)}")

        if addresses:
            for address in addresses:
                print(
                    f"  ALB     : "
                    f"{address.get('hostname') or address.get('ip', 'Unknown')}"
                )

    ingress_name, alb_hostname = get_alb_hostname()

    if alb_hostname:
        success(
            f"Ingress '{ingress_name}' has ALB address: "
            f"{alb_hostname}"
        )
        return alb_hostname

    warning(
        "Ingress exists but AWS ALB hostname is not available yet. "
        "The AWS Load Balancer Controller may still be provisioning."
    )

    return None


# -----------------------------------------------------------------------------
# Check 8 - HTTP /health
# -----------------------------------------------------------------------------

def check_http_health(alb_hostname):
    print()
    print("--------------------------------------------")
    print("  Check 8: HTTP /health Endpoint")
    print("--------------------------------------------")

    if not alb_hostname:
        warning(
            "Skipping HTTP health check because ALB hostname "
            "is not available."
        )
        return

    url = f"http://{alb_hostname}{HEALTH_PATH}"

    info(f"Checking {url}")

    try:
        request = urllib.request.Request(
            url,
            headers={
                "User-Agent": "banking-platform-deployment-verification"
            },
        )

        with urllib.request.urlopen(request, timeout=10) as response:
            status_code = response.status

        if status_code == 200:
            success(
                f"Banking Backend health endpoint returned HTTP {status_code}."
            )
        else:
            failure(
                f"Banking Backend health endpoint returned HTTP "
                f"{status_code}; expected HTTP 200."
            )

    except urllib.error.HTTPError as exc:
        failure(
            f"Health endpoint returned HTTP {exc.code}: {url}"
        )

    except urllib.error.URLError as exc:
        failure(
            f"Could not reach health endpoint: {url} ({exc.reason})"
        )

    except Exception as exc:
        failure(
            f"HTTP health check failed: {url} ({exc})"
        )


# -----------------------------------------------------------------------------
# Final summary
# -----------------------------------------------------------------------------

def print_summary(alb_hostname):
    print()
    print("============================================")

    if ERRORS == 0:
        print(f"{GREEN}  ALL CHECKS PASSED{NC}")
        print()
        print("  Banking Platform deployment is healthy.")

        if alb_hostname:
            print()
            print(f"  Application URL : http://{alb_hostname}/")
            print(f"  Health URL      : http://{alb_hostname}{HEALTH_PATH}")

    else:
        print(f"{RED}  {ERRORS} CHECK(S) FAILED{NC}")
        print()
        print("  Troubleshooting commands:")
        print(f"    kubectl get pods -n {NAMESPACE}")
        print(f"    kubectl get deployment -n {NAMESPACE}")
        print(f"    kubectl describe deployment -n {NAMESPACE} {APP_NAME}")
        print(f"    kubectl logs -n {NAMESPACE} deployment/{APP_NAME}")
        print(f"    kubectl get svc -n {NAMESPACE}")
        print(f"    kubectl get ingress -n {NAMESPACE}")
        print(f"    kubectl get externalsecret -n {NAMESPACE}")
        print(f"    kubectl get applications -n {ARGOCD_NAMESPACE}")

    print("============================================")
    print()


# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

def main():
    check_required_tools()
    print_header()

    if not check_kubernetes():
        sys.exit(1)

    deployment_name = check_deployment()

    check_rollout_and_pods(deployment_name)

    check_argocd()

    check_external_secret()

    check_service(deployment_name)

    alb_hostname = check_ingress()

    check_http_health(alb_hostname)

    print_summary(alb_hostname)

    sys.exit(1 if ERRORS > 0 else 0)


if __name__ == "__main__":
    main()
