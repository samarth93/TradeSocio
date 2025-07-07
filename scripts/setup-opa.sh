#!/bin/bash

# OPA Gatekeeper Setup Script
# This script installs and configures OPA Gatekeeper with security policies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if minikube is running
print_status "Checking Minikube status..."
if ! minikube status > /dev/null 2>&1; then
    print_error "Minikube is not running. Please start Minikube first:"
    echo "  minikube start"
    exit 1
fi

# Set context to minikube
print_status "Setting kubectl context to minikube..."
kubectl config use-context minikube

# Install OPA Gatekeeper
print_status "Installing OPA Gatekeeper..."
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# Wait for Gatekeeper to be ready
print_status "Waiting for Gatekeeper to be ready..."
kubectl wait --for=condition=ready pod -l gatekeeper.sh/operation=webhook -n gatekeeper-system --timeout=300s

# Apply constraint templates
print_status "Applying constraint templates..."
kubectl apply -f k8s/opa-policies/constraint-template.yaml

# Wait a bit for templates to be processed
print_status "Waiting for constraint templates to be processed..."
sleep 10

# Apply constraints
print_status "Applying constraints..."
kubectl apply -f k8s/opa-policies/constraints.yaml

# Check constraint status
print_status "Checking constraint status..."
kubectl get constraints

# Show violations (if any)
print_status "Checking for violations..."
kubectl get constraints -o json | jq '.items[] | select(.status.violations != null) | {name: .metadata.name, violations: .status.violations}'

print_status "OPA Gatekeeper setup completed successfully!"
print_status "Security policies are now enforced:"
echo "  - Pods must run as non-root user"
echo "  - Pods must not allow privilege escalation"
echo "  - Pods must specify fsGroup in security context"
echo "  - Pods must not use default service account"
echo

print_status "To test the policies, try creating a pod without security context:"
echo "  kubectl run test-pod --image=nginx --dry-run=server -o yaml"
echo

print_status "To view all constraints:"
echo "  kubectl get constraints"
echo

print_status "To view constraint violations:"
echo "  kubectl describe constraints" 