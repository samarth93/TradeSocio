#!/bin/bash

# DevOps Challenge Deployment Script
# This script deploys the application to Minikube

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

# Check if minikube is running
print_status "Checking Minikube status..."
if ! minikube status > /dev/null 2>&1; then
    print_error "Minikube is not running. Please start Minikube first:"
    echo "  minikube start"
    exit 1
fi

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    print_error "helm is not installed or not in PATH"
    exit 1
fi

# Set context to minikube
print_status "Setting kubectl context to minikube..."
kubectl config use-context minikube

# Enable required addons
print_status "Enabling required Minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server

# Create namespace if it doesn't exist
NAMESPACE="devops-challenge"
print_status "Creating namespace: $NAMESPACE"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Helm repositories
print_status "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus (optional)
read -p "Do you want to install Prometheus for monitoring? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Installing Prometheus..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
        --namespace monitoring \
        --create-namespace \
        --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
        --set grafana.adminPassword=admin123 \
        --wait
    
    print_status "Prometheus installed successfully!"
    print_status "Grafana admin password: admin123"
fi

# Build Docker image in Minikube
print_status "Building Docker image in Minikube..."
eval $(minikube docker-env)
docker build -t devops-challenge:latest ./app

# Deploy the application using Helm
print_status "Deploying application using Helm..."
helm upgrade --install devops-challenge ./helm-chart/devops-chart \
    --namespace $NAMESPACE \
    --set image.repository=devops-challenge \
    --set image.tag=latest \
    --set image.pullPolicy=Never \
    --wait

# Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/devops-challenge -n $NAMESPACE

# Run Helm tests
print_status "Running Helm tests..."
helm test devops-challenge -n $NAMESPACE

# Get service information
print_status "Getting service information..."
kubectl get services -n $NAMESPACE

# Port forward to access the application
print_status "Setting up port forwarding..."
echo
print_status "Application deployed successfully!"
print_status "To access the application:"
echo "  kubectl port-forward service/devops-challenge 8080:80 -n $NAMESPACE"
echo
print_status "Then visit: http://localhost:8080/api"
print_status "Health check: http://localhost:8080/api/health"
print_status "Metrics: http://localhost:8080/actuator/prometheus"
echo

# Show useful commands
print_status "Useful commands:"
echo "  # View logs"
echo "  kubectl logs -f deployment/devops-challenge -n $NAMESPACE"
echo
echo "  # Scale deployment"
echo "  kubectl scale deployment devops-challenge --replicas=3 -n $NAMESPACE"
echo
echo "  # Update deployment"
echo "  helm upgrade devops-challenge ./helm-chart/devops-chart -n $NAMESPACE"
echo
echo "  # Uninstall"
echo "  helm uninstall devops-challenge -n $NAMESPACE"
echo

if helm list -n monitoring | grep -q prometheus; then
    print_status "Prometheus is installed. To access:"
    echo "  # Prometheus UI"
    echo "  kubectl port-forward service/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring"
    echo
    echo "  # Grafana UI"
    echo "  kubectl port-forward service/prometheus-grafana 3000:80 -n monitoring"
    echo "  Username: admin, Password: admin123"
fi

print_status "Deployment completed successfully!" 