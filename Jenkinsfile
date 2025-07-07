pipeline {
    agent any
    
    environment {
        // Application details
        APP_NAME = 'devops-challenge'
        APP_VERSION = '1.0.0'
        DOCKER_IMAGE = "${APP_NAME}:${BUILD_NUMBER}"
        DOCKER_LATEST = "${APP_NAME}:latest"
        
        // Docker registry (can be Docker Hub, ECR, etc.)
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_REPO = 'samarthdev'  // Change this to your Docker Hub username
        
        // Kubernetes namespace
        K8S_NAMESPACE = 'devops-challenge'
        
        // Tools
        MAVEN_OPTS = '-Dmaven.repo.local=.m2/repository'
    }
    
    tools {
        maven 'Maven-3.9.6'  // Make sure this matches your Jenkins Maven installation
        jdk 'OpenJDK-21'     // Make sure this matches your Jenkins JDK installation
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Checking out source code...'
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
                echo "Git commit: ${env.GIT_COMMIT_SHORT}"
            }
        }
        
        stage('Build & Test') {
            parallel {
                stage('Compile & Package') {
                    steps {
                        dir('app') {
                            echo '🔨 Building application...'
                            sh 'mvn clean compile -DskipTests'
                            sh 'mvn package -DskipTests'
                            
                            // Archive the JAR file
                            archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: false
                        }
                    }
                }
                
                stage('Unit Tests') {
                    steps {
                        dir('app') {
                            echo '🧪 Running unit tests...'
                            sh 'mvn test'
                            
                            // Publish test results
                            publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                        }
                    }
                    post {
                        always {
                            dir('app') {
                                // Archive test reports
                                archiveArtifacts artifacts: 'target/surefire-reports/*', allowEmptyArchive: true
                            }
                        }
                    }
                }
                
                stage('Code Quality') {
                    steps {
                        dir('app') {
                            echo '📊 Running code quality checks...'
                            // Run SpotBugs
                            sh 'mvn spotbugs:check || true'
                            
                            // Generate JaCoCo coverage report
                            sh 'mvn jacoco:report || true'
                        }
                    }
                    post {
                        always {
                            dir('app') {
                                // Archive quality reports
                                archiveArtifacts artifacts: 'target/site/**', allowEmptyArchive: true
                            }
                        }
                    }
                }
            }
        }
        
        stage('Security Scan') {
            parallel {
                stage('Dependency Check') {
                    steps {
                        dir('app') {
                            echo '🔒 Running OWASP dependency check...'
                            sh '''
                                mvn org.owasp:dependency-check-maven:check \
                                    -DfailBuildOnCVSS=7 \
                                    -DsuppressionsFile=../k8s/opa-policies/owasp-suppressions.xml || true
                            '''
                        }
                    }
                    post {
                        always {
                            dir('app') {
                                archiveArtifacts artifacts: 'target/dependency-check-report.html', allowEmptyArchive: true
                            }
                        }
                    }
                }
                
                stage('Code Analysis') {
                    steps {
                        echo '📋 Running static code analysis...'
                        // Placeholder for SonarQube or other tools
                        sh 'echo "Code analysis placeholder - integrate SonarQube here"'
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    dir('app') {
                        echo '🐳 Building Docker image...'
                        
                        // Build the Docker image
                        def image = docker.build("${DOCKER_REPO}/${DOCKER_IMAGE}")
                        
                        // Tag as latest
                        sh "docker tag ${DOCKER_REPO}/${DOCKER_IMAGE} ${DOCKER_REPO}/${DOCKER_LATEST}"
                        
                        // Store image ID for later use
                        env.DOCKER_IMAGE_ID = image.id
                        
                        echo "Built Docker image: ${DOCKER_REPO}/${DOCKER_IMAGE}"
                    }
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo '🧪 Testing Docker image...'
                    
                    // Start container for testing
                    def containerId = sh(
                        script: "docker run -d -p 8083:8080 --name test-${BUILD_NUMBER} ${DOCKER_REPO}/${DOCKER_IMAGE}",
                        returnStdout: true
                    ).trim()
                    
                    try {
                        // Wait for application to start
                        sleep 15
                        
                        // Test health endpoint
                        sh '''
                            curl -f http://localhost:8083/api/health || exit 1
                            echo "✅ Health check passed"
                        '''
                        
                        // Test main API endpoint
                        sh '''
                            curl -f http://localhost:8083/api || exit 1
                            echo "✅ API endpoint test passed"
                        '''
                        
                        // Test metrics endpoint
                        sh '''
                            curl -f http://localhost:8083/actuator/prometheus | grep -q "api_calls_total" || exit 1
                            echo "✅ Metrics endpoint test passed"
                        '''
                        
                    } finally {
                        // Always stop and remove the test container
                        sh "docker stop test-${BUILD_NUMBER} || true"
                        sh "docker rm test-${BUILD_NUMBER} || true"
                    }
                }
            }
        }
        
        stage('Security Scan Docker Image') {
            steps {
                script {
                    echo '🔍 Scanning Docker image for vulnerabilities...'
                    
                    // Run Trivy security scan
                    sh """
                        docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \\
                            aquasec/trivy image --format table \\
                            ${DOCKER_REPO}/${DOCKER_IMAGE} || true
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                }
            }
            steps {
                script {
                    echo '📤 Pushing Docker image to registry...'
                    
                    // Note: In a real environment, you would configure Docker registry credentials
                    // docker.withRegistry('https://registry.hub.docker.com', 'docker-hub-credentials') {
                    //     docker.image("${DOCKER_REPO}/${DOCKER_IMAGE}").push()
                    //     docker.image("${DOCKER_REPO}/${DOCKER_LATEST}").push()
                    // }
                    
                    echo "Would push: ${DOCKER_REPO}/${DOCKER_IMAGE}"
                    echo "Would push: ${DOCKER_REPO}/${DOCKER_LATEST}"
                    echo "⚠️  Docker push skipped - configure registry credentials first"
                }
            }
        }
        
        stage('Deploy to Development') {
            when {
                branch 'develop'
            }
            steps {
                script {
                    echo '🚀 Deploying to development environment...'
                    
                    // Update Kubernetes deployment
                    sh """
                        # Set kubectl context (if needed)
                        # kubectl config use-context dev-cluster
                        
                        # Update deployment image
                        kubectl set image deployment/${APP_NAME} \\
                            ${APP_NAME}=${DOCKER_REPO}/${DOCKER_IMAGE} \\
                            -n ${K8S_NAMESPACE}-dev || echo "Deployment not found, will create new one"
                        
                        # Wait for rollout
                        kubectl rollout status deployment/${APP_NAME} -n ${K8S_NAMESPACE}-dev --timeout=300s || true
                    """
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo '🎭 Deploying to staging environment...'
                    
                    // Deploy using Helm
                    sh """
                        helm upgrade --install ${APP_NAME}-staging ./helm-chart/devops-chart \\
                            --namespace ${K8S_NAMESPACE}-staging \\
                            --create-namespace \\
                            --set image.repository=${DOCKER_REPO}/${APP_NAME} \\
                            --set image.tag=${BUILD_NUMBER} \\
                            --set environment=staging \\
                            --wait
                    """
                    
                    // Run Helm tests
                    sh "helm test ${APP_NAME}-staging -n ${K8S_NAMESPACE}-staging"
                }
            }
        }
        
        stage('Integration Tests') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            parallel {
                stage('API Tests') {
                    steps {
                        echo '🔗 Running integration tests...'
                        dir('app') {
                            sh 'mvn verify -Dspring.profiles.active=test || true'
                        }
                    }
                }
                
                stage('Load Tests') {
                    steps {
                        echo '⚡ Running load tests...'
                        script {
                            // Placeholder for load testing
                            sh '''
                                echo "Load testing placeholder"
                                echo "Would run: artillery run load-test.yml"
                                echo "Would run: k6 run performance-test.js"
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Production Deployment Approval') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo '⏳ Waiting for production deployment approval...'
                    
                    // Manual approval for production
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: 'Deploy to production?', 
                              ok: 'Deploy',
                              submitterParameter: 'DEPLOYER'
                    }
                    
                    echo "Deployment approved by: ${env.DEPLOYER}"
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    echo '🌟 Deploying to production environment...'
                    
                    // Blue-Green deployment using Helm
                    sh """
                        # Deploy new version (green)
                        helm upgrade --install ${APP_NAME} ./helm-chart/devops-chart \\
                            --namespace ${K8S_NAMESPACE} \\
                            --create-namespace \\
                            --set image.repository=${DOCKER_REPO}/${APP_NAME} \\
                            --set image.tag=${BUILD_NUMBER} \\
                            --set environment=production \\
                            --set replicaCount=3 \\
                            --wait
                        
                        # Verify deployment
                        kubectl get pods -n ${K8S_NAMESPACE}
                        kubectl get services -n ${K8S_NAMESPACE}
                        
                        # Run production smoke tests
                        helm test ${APP_NAME} -n ${K8S_NAMESPACE}
                    """
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            
            // Clean up Docker images
            sh """
                docker rmi ${DOCKER_REPO}/${DOCKER_IMAGE} || true
                docker system prune -f || true
            """
            
            // Archive logs
            archiveArtifacts artifacts: '**/target/logs/**', allowEmptyArchive: true
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
            
            // Send notifications
            script {
                def message = """
                🎉 Build #${BUILD_NUMBER} completed successfully!
                
                📋 Details:
                • Project: ${APP_NAME}
                • Version: ${APP_VERSION}
                • Commit: ${env.GIT_COMMIT_SHORT}
                • Docker Image: ${DOCKER_REPO}/${DOCKER_IMAGE}
                • Duration: ${currentBuild.durationString}
                
                🔗 Build URL: ${BUILD_URL}
                """
                
                echo message
                // slackSend(channel: '#deployments', message: message, color: 'good')
            }
        }
        
        failure {
            echo '❌ Pipeline failed!'
            
            script {
                def message = """
                🚨 Build #${BUILD_NUMBER} failed!
                
                📋 Details:
                • Project: ${APP_NAME}
                • Commit: ${env.GIT_COMMIT_SHORT}
                • Stage: ${env.STAGE_NAME}
                • Duration: ${currentBuild.durationString}
                
                🔗 Build URL: ${BUILD_URL}
                """
                
                echo message
                // slackSend(channel: '#deployments', message: message, color: 'danger')
            }
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings!'
        }
    }
} 