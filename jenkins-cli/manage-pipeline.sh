#!/bin/bash

# Jenkins Pipeline Management Script
# Provides convenient commands for managing the DevOps pipeline

set -e

# Configuration
JENKINS_URL="http://localhost:8080/"
JENKINS_USER="samarth"
JENKINS_TOKEN="11b89b2f9fedf58e8095f2b7a336643952"
JENKINS_CLI_JAR="jenkins-cli.jar"
PIPELINE_NAME="devops-pipeline"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run Jenkins CLI commands
run_jenkins_cli() {
    java -jar "$JENKINS_CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_TOKEN" "$@"
}

# Function to display help
show_help() {
    echo -e "${BLUE}Jenkins Pipeline Management Script${NC}"
    echo "=================================="
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build         - Trigger a new build"
    echo "  build-params  - Trigger build with parameters"
    echo "  status        - Show pipeline status"
    echo "  logs          - Show build logs"
    echo "  list          - List all jobs"
    echo "  console       - Show console output of last build"
    echo "  stop          - Stop current build"
    echo "  delete        - Delete the pipeline job"
    echo "  recreate      - Delete and recreate the pipeline"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 build-params SKIP_TESTS=true"
    echo "  $0 status"
    echo "  $0 logs"
}

# Function to trigger a build
trigger_build() {
    echo -e "${YELLOW}🚀 Triggering build for $PIPELINE_NAME...${NC}"
    run_jenkins_cli build "$PIPELINE_NAME"
    echo -e "${GREEN}✅ Build triggered successfully!${NC}"
    echo "Check status with: $0 status"
    echo "View logs with: $0 logs"
}

# Function to trigger build with parameters
trigger_build_with_params() {
    echo -e "${YELLOW}🚀 Triggering parameterized build for $PIPELINE_NAME...${NC}"
    run_jenkins_cli build "$PIPELINE_NAME" -p "$1"
    echo -e "${GREEN}✅ Parameterized build triggered successfully!${NC}"
    echo "Parameters: $1"
}

# Function to show pipeline status
show_status() {
    echo -e "${BLUE}📊 Pipeline Status for $PIPELINE_NAME:${NC}"
    echo "=================================="
    
    # Get job info
    run_jenkins_cli get-job "$PIPELINE_NAME" | grep -E "(description|disabled)" || true
    
    # Show recent builds
    echo -e "\n${YELLOW}Recent Builds:${NC}"
    run_jenkins_cli list-builds "$PIPELINE_NAME" | head -10 || true
}

# Function to show build logs
show_logs() {
    echo -e "${BLUE}📋 Build Logs for $PIPELINE_NAME:${NC}"
    echo "=================================="
    
    # Get the last build number
    BUILD_NUMBER=$(run_jenkins_cli list-builds "$PIPELINE_NAME" | head -1 | cut -d' ' -f1)
    
    if [ -n "$BUILD_NUMBER" ]; then
        echo -e "${YELLOW}Showing logs for build #$BUILD_NUMBER:${NC}"
        run_jenkins_cli console "$PIPELINE_NAME" "$BUILD_NUMBER"
    else
        echo -e "${RED}No builds found for $PIPELINE_NAME${NC}"
    fi
}

# Function to list all jobs
list_jobs() {
    echo -e "${BLUE}📋 All Jenkins Jobs:${NC}"
    echo "===================="
    run_jenkins_cli list-jobs
}

# Function to show console output
show_console() {
    echo -e "${BLUE}💻 Console Output for $PIPELINE_NAME:${NC}"
    echo "===================================="
    run_jenkins_cli console "$PIPELINE_NAME"
}

# Function to stop current build
stop_build() {
    echo -e "${YELLOW}🛑 Stopping current build for $PIPELINE_NAME...${NC}"
    
    # Get the last build number
    BUILD_NUMBER=$(run_jenkins_cli list-builds "$PIPELINE_NAME" | head -1 | cut -d' ' -f1)
    
    if [ -n "$BUILD_NUMBER" ]; then
        run_jenkins_cli stop-builds "$PIPELINE_NAME" "$BUILD_NUMBER"
        echo -e "${GREEN}✅ Build #$BUILD_NUMBER stopped successfully!${NC}"
    else
        echo -e "${RED}No active builds found for $PIPELINE_NAME${NC}"
    fi
}

# Function to delete the pipeline
delete_pipeline() {
    echo -e "${RED}🗑️  Deleting pipeline $PIPELINE_NAME...${NC}"
    read -p "Are you sure you want to delete the pipeline? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_jenkins_cli delete-job "$PIPELINE_NAME"
        echo -e "${GREEN}✅ Pipeline deleted successfully!${NC}"
    else
        echo -e "${YELLOW}❌ Pipeline deletion cancelled.${NC}"
    fi
}

# Function to recreate the pipeline
recreate_pipeline() {
    echo -e "${YELLOW}🔄 Recreating pipeline $PIPELINE_NAME...${NC}"
    
    # Delete existing pipeline
    run_jenkins_cli delete-job "$PIPELINE_NAME" 2>/dev/null || true
    
    # Create new pipeline
    run_jenkins_cli create-job "$PIPELINE_NAME" < simple-pipeline.xml
    
    echo -e "${GREEN}✅ Pipeline recreated successfully!${NC}"
}

# Function to check Jenkins connection
check_connection() {
    echo -e "${BLUE}🔗 Checking Jenkins connection...${NC}"
    
    if run_jenkins_cli who-am-i > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Connected to Jenkins as: $(run_jenkins_cli who-am-i)${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to connect to Jenkins!${NC}"
        echo "Please check:"
        echo "  - Jenkins is running at $JENKINS_URL"
        echo "  - Username and token are correct"
        echo "  - jenkins-cli.jar is present"
        return 1
    fi
}

# Main script logic
main() {
    # Check if jenkins-cli.jar exists
    if [ ! -f "$JENKINS_CLI_JAR" ]; then
        echo -e "${RED}❌ jenkins-cli.jar not found!${NC}"
        echo "Please download it first:"
        echo "  wget $JENKINS_URL/jnlpJars/jenkins-cli.jar"
        exit 1
    fi
    
    # Check connection first
    if ! check_connection; then
        exit 1
    fi
    
    # Handle commands
    case "${1:-help}" in
        "build")
            trigger_build
            ;;
        "build-params")
            if [ -z "$2" ]; then
                echo -e "${RED}❌ Please provide parameters${NC}"
                echo "Example: $0 build-params SKIP_TESTS=true"
                exit 1
            fi
            trigger_build_with_params "$2"
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "list")
            list_jobs
            ;;
        "console")
            show_console
            ;;
        "stop")
            stop_build
            ;;
        "delete")
            delete_pipeline
            ;;
        "recreate")
            recreate_pipeline
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 