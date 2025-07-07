# 🚀 Full-Stack DevOps Assignment

A comprehensive DevOps showcase demonstrating backend development, containerization, CI/CD, Kubernetes orchestration, Helm packaging, and monitoring capabilities.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Quick Start](#quick-start)
- [Detailed Steps](#detailed-steps)
- [API Documentation](#api-documentation)
- [Monitoring & Metrics](#monitoring--metrics)
- [Security & Policies](#security--policies)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Project Overview

This project demonstrates a complete DevOps pipeline including:

- **Backend API**: Java Spring Boot application with Prometheus metrics
- **Containerization**: Multi-stage Docker build with security best practices
- **CI/CD**: Jenkins pipeline with automated testing and deployment
- **Orchestration**: Kubernetes deployment with Helm charts
- **Monitoring**: Prometheus metrics and Grafana dashboards
- **Security**: OPA Gatekeeper policies and security scanning

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Developer     │    │   Jenkins       │    │   Kubernetes    │
│   Workstation   │───▶│   CI/CD         │───▶│   Cluster       │
│                 │    │   Pipeline      │    │   (Minikube)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        │                       │                       │
        ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Source Code   │    │   Docker        │    │   Monitoring    │
│   (GitHub)      │    │   Registry      │    │   (Prometheus)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Prerequisites

### Required Tools (✅ Verified)
- Docker (v28.3.0) - ✅ Running
- kubectl (v1.29.15) - ✅ Installed
- Minikube (v1.35.0) - ✅ Running
- Helm (v3.18.3) - ✅ Installed
- Java (OpenJDK 21.0.7) - ✅ Installed
- Jenkins (localhost:8080) - ✅ Running
- Git (v2.43.0) - ✅ Installed

### Jenkins Configuration
- URL: http://localhost:8080/
- User: samarth
- API Token: 11b89b2f9fedf58e8095f2b7a336643952

## 🚀 Quick Start

```bash
# 1. Clone and setup
git clone <repository-url>
cd devops-assignment

# 2. Run locally (application runs on port 8081)
cd app && mvn spring-boot:run

# 3. Build Docker image
cd app && docker build -t devops-app:latest .

# 4. Deploy to Kubernetes
./scripts/deploy.sh

# 5. Access application
kubectl port-forward service/devops-challenge 8082:80 -n devops-challenge
curl http://localhost:8082/api
```

## 📝 Detailed Steps

### Step 0: Environment Pre-check ✅
All required tools verified and running:
- Docker daemon: ✅ Running
- Minikube cluster: ✅ Running
- Jenkins server: ✅ Accessible at localhost:8080
- All CLI tools: ✅ Installed and accessible

### Step 1: Project Workspace ✅
Created directory structure:
```
.
├── app/                    # Application source code
├── helm-chart/            # Helm chart for Kubernetes deployment
├── .github/workflows/     # GitHub Actions CI/CD
├── k8s-deployment/        # Kubernetes manifests
├── jenkins-cli/           # Jenkins CLI scripts
├── scripts/               # Deployment scripts
├── Dockerfile            # Container definition
└── README.md             # This documentation
```

### Step 2: API Service
**Command executed:**
```bash
# Create Spring Boot application with Prometheus metrics
mvn archetype:generate -DgroupId=com.devops.challenge -DartifactId=devops-app
```

**API Endpoints:**
- `GET /api` - Returns request headers, method, and body
- `GET /api/health` - Health check endpoint
- `GET /actuator/prometheus` - Prometheus metrics

### Step 3: Dockerization
**Commands executed:**
```bash
# Build Docker image
docker build -t devops-app:latest .

# Test container
docker run -p 8080:8080 devops-app:latest

# Security scan
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image devops-app:latest
```

### Step 4: Jenkins CI/CD Pipeline
**Commands executed:**
```bash
# Download Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Create pipeline job
java -jar jenkins-cli.jar -s http://localhost:8080/ \
  -auth samarth:11b89b2f9fedf58e8095f2b7a336643952 \
  create-job devops-pipeline < jenkins-cli/pipeline-config.xml

# Trigger build
java -jar jenkins-cli.jar -s http://localhost:8080/ \
  -auth samarth:11b89b2f9fedf58e8095f2b7a336643952 \
  build devops-pipeline
```

### Step 5: Helm Chart
**Commands executed:**
```bash
# Create Helm chart
helm create devops-chart

# Install chart
helm install devops-release ./helm-chart/devops-chart

# Run Helm tests
helm test devops-release
```

### Step 6: Kubernetes Deployment
**Commands executed:**
```bash
# Deploy to Minikube
kubectl apply -f k8s-deployment/

# Verify deployment
kubectl get pods,services,ingress

# Test external access
minikube service devops-service --url
curl $(minikube service devops-service --url)/api
```

### Step 7: OPA Security Policies (Bonus)
**Commands executed:**
```bash
# Install OPA Gatekeeper
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# Apply security policies
kubectl apply -f k8s-deployment/opa-policies/

# Test policy enforcement
kubectl run test-pod --image=nginx --dry-run=server -o yaml
```

## 🔌 API Documentation

### Endpoints

#### GET /api
Returns detailed request information including headers, method, and body.

**Example Request:**
```bash
curl -X GET http://localhost:8081/api \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: test-value"
```

**Example Response:**
```json
{
  "method": "GET",
  "headers": {
    "Content-Type": "application/json",
    "X-Custom-Header": "test-value",
    "User-Agent": "curl/7.68.0"
  },
  "body": null,
  "timestamp": "2024-01-01T12:00:00",
  "requestUri": "/api",
  "remoteAddr": "127.0.0.1"
}
```

#### POST /api
Accepts JSON payload and returns request details.

**Example Request:**
```bash
curl -X POST http://localhost:8081/api \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello World", "timestamp": "2024-01-01T00:00:00Z"}'
```

#### GET /api/health
Health check endpoint for monitoring.

**Example Response:**
```json
{
  "status": "UP",
  "timestamp": "2024-01-01T12:00:00",
  "service": "DevOps Challenge API",
  "version": "1.0.0"
}
```

## 📊 Monitoring & Metrics

### Prometheus Metrics
Available at `/actuator/prometheus`:

- `api_calls_total` - Total API calls
- `api_get_requests_total` - GET requests counter
- `api_post_requests_total` - POST requests counter
- `http_server_requests_seconds` - Request duration histogram
- `jvm_memory_used_bytes` - JVM memory usage
- `system_cpu_usage` - System CPU usage

### Grafana Dashboard
Access Grafana at `http://localhost:3000` (admin/admin123) after installing monitoring stack.

**Key Metrics to Monitor:**
- Request rate (RPS)
- Response time (P95, P99)
- Error rate
- CPU and memory usage
- JVM heap usage

## 🛡️ Security & Policies

### OPA Gatekeeper Policies
1. **No Default Service Account**: Prevents pods from using default service account
2. **Non-Root Containers**: Ensures containers run as non-root user
3. **Security Context Required**: Mandates security context configuration
4. **Resource Limits**: Requires CPU/memory limits on containers

### Security Scanning
- **Trivy**: Container vulnerability scanning
- **OWASP Dependency Check**: Dependency vulnerability scanning
- **SonarQube**: Code quality and security analysis

## 🔧 Troubleshooting

### Common Issues

#### Jenkins Pipeline Fails
```bash
# Check Jenkins logs
docker logs jenkins-container

# Verify Jenkins CLI connection
java -jar jenkins-cli.jar -s http://localhost:8080/ \
  -auth samarth:11b89b2f9fedf58e8095f2b7a336643952 who-am-i
```

#### Kubernetes Deployment Issues
```bash
# Check pod status
kubectl get pods -n devops-challenge

# View pod logs
kubectl logs -f deployment/devops-challenge -n devops-challenge

# Describe pod for events
kubectl describe pod <pod-name> -n devops-challenge
```

#### Helm Chart Issues
```bash
# Validate chart
helm lint ./helm-chart/devops-chart

# Debug template rendering
helm template devops-release ./helm-chart/devops-chart

# Check release status
helm status devops-release
```

#### Docker Build Issues
```bash
# Build with verbose output
docker build -t devops-app:latest . --progress=plain

# Check build context
docker build -t devops-app:latest . --no-cache

# Inspect image layers
docker history devops-app:latest
```

### Useful Commands

```bash
# View all resources
kubectl get all -n devops-challenge

# Port forward to access service
kubectl port-forward service/devops-challenge 8080:80 -n devops-challenge

# Scale deployment
kubectl scale deployment devops-challenge --replicas=3 -n devops-challenge

# View Helm releases
helm list --all-namespaces

# Check OPA constraints
kubectl get constraints

# View metrics
curl http://localhost:8080/actuator/prometheus | grep api_calls
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Spring Boot team for the excellent framework
- Kubernetes community for container orchestration
- Prometheus team for monitoring solutions
- Jenkins community for CI/CD automation
- All open-source contributors

---

**Last Updated:** 2024-01-01
**Project Status:** ✅ Complete
**Environment:** Minikube + Jenkins + Docker 