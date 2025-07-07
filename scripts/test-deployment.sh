#!/bin/bash

# Comprehensive Deployment Testing Script
# Tests all aspects of the DevOps Challenge deployment

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="devops-challenge"
APP_NAME="devops-challenge"
HELM_RELEASE="devops-challenge"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_header() {
    echo ""
    echo "=================================="
    print_status $BLUE "$1"
    echo "=================================="
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to wait for pods to be ready
wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}
    
    print_status $YELLOW "⏳ Waiting for pods to be ready in namespace $namespace..."
    
    if kubectl wait --for=condition=Ready pod --all -n "$namespace" --timeout="${timeout}s"; then
        print_status $GREEN "✅ All pods are ready!"
        return 0
    else
        print_status $RED "❌ Timeout waiting for pods to be ready"
        return 1
    fi
}

# Function to test API endpoint
test_api_endpoint() {
    local url=$1
    local expected_status=${2:-200}
    local description=$3
    
    print_status $YELLOW "🧪 Testing: $description"
    
    if response=$(curl -s -w "%{http_code}" -o /tmp/response.json "$url"); then
        status_code=${response: -3}
        if [ "$status_code" -eq "$expected_status" ]; then
            print_status $GREEN "✅ $description - Status: $status_code"
            if command_exists jq && [ -s /tmp/response.json ]; then
                echo "Response:"
                jq '.' /tmp/response.json 2>/dev/null || cat /tmp/response.json
            fi
            return 0
        else
            print_status $RED "❌ $description - Expected: $expected_status, Got: $status_code"
            return 1
        fi
    else
        print_status $RED "❌ $description - Failed to connect"
        return 1
    fi
}

# Function to check Kubernetes resources
check_k8s_resources() {
    print_header "🔍 Checking Kubernetes Resources"
    
    # Check namespace
    if kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        print_status $GREEN "✅ Namespace '$NAMESPACE' exists"
    else
        print_status $RED "❌ Namespace '$NAMESPACE' not found"
        return 1
    fi
    
    # Check deployment
    if kubectl get deployment "$APP_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
        print_status $GREEN "✅ Deployment '$APP_NAME' exists"
        
        # Check deployment status
        local ready_replicas=$(kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
        local desired_replicas=$(kubectl get deployment "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
        
        if [ "$ready_replicas" = "$desired_replicas" ]; then
            print_status $GREEN "✅ Deployment is ready ($ready_replicas/$desired_replicas)"
        else
            print_status $YELLOW "⚠️  Deployment not fully ready ($ready_replicas/$desired_replicas)"
        fi
    else
        print_status $RED "❌ Deployment '$APP_NAME' not found"
        return 1
    fi
    
    # Check service
    if kubectl get service "$APP_NAME" -n "$NAMESPACE" >/dev/null 2>&1; then
        print_status $GREEN "✅ Service '$APP_NAME' exists"
        
        # Show service details
        local cluster_ip=$(kubectl get service "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}')
        local port=$(kubectl get service "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].port}')
        print_status $BLUE "   Service ClusterIP: $cluster_ip:$port"
    else
        print_status $RED "❌ Service '$APP_NAME' not found"
        return 1
    fi
    
    # Check pods
    print_status $YELLOW "📋 Pod Status:"
    kubectl get pods -n "$NAMESPACE" -o wide
    
    return 0
}

# Function to check Helm release
check_helm_release() {
    print_header "📦 Checking Helm Release"
    
    if helm list -n "$NAMESPACE" | grep -q "$HELM_RELEASE"; then
        print_status $GREEN "✅ Helm release '$HELM_RELEASE' found"
        
        # Show release details
        helm status "$HELM_RELEASE" -n "$NAMESPACE"
        
        return 0
    else
        print_status $RED "❌ Helm release '$HELM_RELEASE' not found"
        return 1
    fi
}

# Function to run Helm tests
run_helm_tests() {
    print_header "🧪 Running Helm Tests"
    
    if helm test "$HELM_RELEASE" -n "$NAMESPACE"; then
        print_status $GREEN "✅ Helm tests passed"
        return 0
    else
        print_status $RED "❌ Helm tests failed"
        return 1
    fi
}

# Function to test API endpoints
test_api_endpoints() {
    print_header "🌐 Testing API Endpoints"
    
    # Set up port forwarding
    print_status $YELLOW "🔗 Setting up port forwarding..."
    kubectl port-forward service/"$APP_NAME" 8087:80 -n "$NAMESPACE" >/dev/null 2>&1 &
    local pf_pid=$!
    
    # Wait for port forwarding to be ready
    sleep 5
    
    # Test endpoints
    local base_url="http://localhost:8087"
    local all_tests_passed=true
    
    # Test health endpoint
    if ! test_api_endpoint "$base_url/api/health" 200 "Health Check Endpoint"; then
        all_tests_passed=false
    fi
    
    # Test main API endpoint
    if ! test_api_endpoint "$base_url/api" 200 "Main API Endpoint"; then
        all_tests_passed=false
    fi
    
    # Test info endpoint
    if ! test_api_endpoint "$base_url/api/info" 200 "Info Endpoint"; then
        all_tests_passed=false
    fi
    
    # Test Prometheus metrics
    if ! test_api_endpoint "$base_url/actuator/prometheus" 200 "Prometheus Metrics Endpoint"; then
        all_tests_passed=false
    fi
    
    # Test POST endpoint
    print_status $YELLOW "🧪 Testing POST endpoint with JSON data..."
    if curl -s -X POST "$base_url/api" \
        -H "Content-Type: application/json" \
        -d '{"test": "data", "timestamp": "'$(date -Iseconds)'"}' \
        -w "%{http_code}" -o /tmp/post_response.json | grep -q "200"; then
        print_status $GREEN "✅ POST endpoint test passed"
        if command_exists jq; then
            echo "POST Response:"
            jq '.' /tmp/post_response.json 2>/dev/null || cat /tmp/post_response.json
        fi
    else
        print_status $RED "❌ POST endpoint test failed"
        all_tests_passed=false
    fi
    
    # Clean up port forwarding
    kill $pf_pid 2>/dev/null || true
    
    if $all_tests_passed; then
        print_status $GREEN "✅ All API endpoint tests passed"
        return 0
    else
        print_status $RED "❌ Some API endpoint tests failed"
        return 1
    fi
}

# Function to check OPA policies
check_opa_policies() {
    print_header "🛡️  Checking OPA Security Policies"
    
    # Check if Gatekeeper is installed
    if kubectl get namespace gatekeeper-system >/dev/null 2>&1; then
        print_status $GREEN "✅ OPA Gatekeeper is installed"
        
        # Check Gatekeeper pods
        local gatekeeper_ready=$(kubectl get pods -n gatekeeper-system --no-headers | grep Running | wc -l)
        print_status $BLUE "   Gatekeeper pods running: $gatekeeper_ready"
        
        # Check constraint templates
        local constraint_templates=$(kubectl get constrainttemplates --no-headers | wc -l)
        print_status $BLUE "   Constraint templates: $constraint_templates"
        
        # Check constraints
        local constraints=$(kubectl get constraints --no-headers 2>/dev/null | wc -l || echo "0")
        print_status $BLUE "   Active constraints: $constraints"
        
        # Test policy enforcement
        print_status $YELLOW "🧪 Testing policy enforcement..."
        if kubectl run test-bad-pod --image=nginx --dry-run=server >/dev/null 2>&1; then
            print_status $RED "❌ OPA policies are not enforcing security requirements"
            return 1
        else
            print_status $GREEN "✅ OPA policies are correctly blocking insecure pods"
        fi
        
        return 0
    else
        print_status $YELLOW "⚠️  OPA Gatekeeper not installed"
        return 1
    fi
}

# Function to check monitoring setup
check_monitoring() {
    print_header "📊 Checking Monitoring Setup"
    
    # Check if ServiceMonitor exists
    if kubectl get servicemonitor -n monitoring 2>/dev/null | grep -q "$APP_NAME"; then
        print_status $GREEN "✅ ServiceMonitor exists in monitoring namespace"
    else
        print_status $YELLOW "⚠️  ServiceMonitor not found in monitoring namespace"
    fi
    
    # Check Prometheus annotations on pods
    local pods_with_annotations=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.annotations}' | grep -c "prometheus.io/scrape" || echo "0")
    if [ "$pods_with_annotations" -gt 0 ]; then
        print_status $GREEN "✅ Pods have Prometheus scraping annotations"
    else
        print_status $YELLOW "⚠️  Pods missing Prometheus annotations"
    fi
    
    return 0
}

# Function to generate deployment report
generate_report() {
    print_header "📋 Deployment Report"
    
    local report_file="/tmp/devops-challenge-report.txt"
    
    {
        echo "DevOps Challenge Deployment Report"
        echo "Generated on: $(date)"
        echo "======================================="
        echo ""
        
        echo "Kubernetes Cluster Info:"
        kubectl cluster-info --request-timeout=10s 2>/dev/null || echo "Unable to get cluster info"
        echo ""
        
        echo "Namespace: $NAMESPACE"
        kubectl get all -n "$NAMESPACE"
        echo ""
        
        echo "Helm Releases:"
        helm list -n "$NAMESPACE"
        echo ""
        
        echo "OPA Gatekeeper Status:"
        kubectl get pods -n gatekeeper-system 2>/dev/null || echo "OPA Gatekeeper not installed"
        echo ""
        
        echo "Resource Usage:"
        kubectl top pods -n "$NAMESPACE" 2>/dev/null || echo "Metrics server not available"
        echo ""
        
    } > "$report_file"
    
    print_status $GREEN "📄 Report generated: $report_file"
    echo "Report contents:"
    cat "$report_file"
}

# Main testing function
main() {
    print_header "🚀 DevOps Challenge Deployment Testing"
    
    local overall_success=true
    
    # Check prerequisites
    print_status $YELLOW "🔧 Checking prerequisites..."
    
    local missing_tools=()
    for tool in kubectl helm curl; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_status $RED "❌ Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    print_status $GREEN "✅ All required tools are available"
    
    # Run all checks
    if ! check_k8s_resources; then
        overall_success=false
    fi
    
    if ! check_helm_release; then
        overall_success=false
    fi
    
    if ! wait_for_pods "$NAMESPACE" 60; then
        overall_success=false
    fi
    
    if ! run_helm_tests; then
        overall_success=false
    fi
    
    if ! test_api_endpoints; then
        overall_success=false
    fi
    
    if ! check_opa_policies; then
        print_status $YELLOW "⚠️  OPA policies check had issues (non-critical)"
    fi
    
    if ! check_monitoring; then
        print_status $YELLOW "⚠️  Monitoring setup check had issues (non-critical)"
    fi
    
    # Generate report
    generate_report
    
    # Final status
    print_header "📊 Final Results"
    
    if $overall_success; then
        print_status $GREEN "🎉 All critical tests passed! Deployment is successful."
        
        print_status $BLUE "🔗 Access your application:"
        echo "  kubectl port-forward service/$APP_NAME 8080:80 -n $NAMESPACE"
        echo "  curl http://localhost:8080/api"
        echo ""
        print_status $BLUE "📊 View monitoring:"
        echo "  curl http://localhost:8080/actuator/prometheus"
        echo ""
        print_status $BLUE "🛡️  Check security policies:"
        echo "  kubectl get constraints"
        echo ""
        
        exit 0
    else
        print_status $RED "❌ Some critical tests failed. Please check the logs above."
        exit 1
    fi
}

# Handle script arguments
case "${1:-test}" in
    "test")
        main
        ;;
    "report")
        generate_report
        ;;
    "help"|"--help"|"-h")
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  test    - Run comprehensive deployment tests (default)"
        echo "  report  - Generate deployment report only"
        echo "  help    - Show this help message"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac 