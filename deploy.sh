#!/bin/bash

###############################################################################
# IMS-Collibra Integration - Deployment Script
#
# Usage:
#   ./deploy.sh <environment> <action>
#
# Arguments:
#   environment: dev, test, or prod
#   action: build, deploy, or package
#
# Examples:
#   ./deploy.sh dev build        # Build for development
#   ./deploy.sh test package     # Package for test environment
#   ./deploy.sh prod deploy      # Deploy to production CloudHub
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Validate arguments
if [ $# -lt 2 ]; then
    print_error "Usage: $0 <environment> <action>"
    print_info "Environment: dev, test, prod"
    print_info "Action: build, deploy, package"
    exit 1
fi

ENVIRONMENT=$1
ACTION=$2

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|test|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    print_info "Valid environments: dev, test, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(build|deploy|package)$ ]]; then
    print_error "Invalid action: $ACTION"
    print_info "Valid actions: build, deploy, package"
    exit 1
fi

print_info "Starting deployment process..."
print_info "Environment: $ENVIRONMENT"
print_info "Action: $ACTION"

# Set Maven profile based on environment
MAVEN_PROFILE="-P$ENVIRONMENT"

case $ACTION in
    build)
        print_info "Building MuleSoft application for $ENVIRONMENT..."
        mvn clean compile $MAVEN_PROFILE
        print_info "Build completed successfully!"
        ;;

    package)
        print_info "Packaging MuleSoft application for $ENVIRONMENT..."
        mvn clean package $MAVEN_PROFILE

        if [ -f "target/ims-collibra-integration-1.0.0-mule-application.jar" ]; then
            print_info "Package created successfully!"
            print_info "Location: target/ims-collibra-integration-1.0.0-mule-application.jar"
        else
            print_error "Package creation failed!"
            exit 1
        fi
        ;;

    deploy)
        print_info "Deploying MuleSoft application to CloudHub ($ENVIRONMENT)..."

        # Check if credentials are set
        if [ -z "$ANYPOINT_USERNAME" ] || [ -z "$ANYPOINT_PASSWORD" ]; then
            print_warn "CloudHub credentials not found in environment variables"
            print_info "Please set ANYPOINT_USERNAME and ANYPOINT_PASSWORD"
            read -p "Enter Anypoint Username: " ANYPOINT_USERNAME
            read -s -p "Enter Anypoint Password: " ANYPOINT_PASSWORD
            echo
        fi

        # Set CloudHub environment
        if [ "$ENVIRONMENT" == "prod" ]; then
            CLOUDHUB_ENV="Production"
        elif [ "$ENVIRONMENT" == "test" ]; then
            CLOUDHUB_ENV="Test"
        else
            CLOUDHUB_ENV="Development"
        fi

        print_info "Deploying to CloudHub environment: $CLOUDHUB_ENV"

        mvn clean deploy -DmuleDeploy \
            -Dmule.env=$ENVIRONMENT \
            -Danypoint.username=$ANYPOINT_USERNAME \
            -Danypoint.password=$ANYPOINT_PASSWORD \
            -Dcloudhub.environment=$CLOUDHUB_ENV \
            -Dcloudhub.workerType=MICRO \
            -Dcloudhub.workers=1 \
            -Dcloudhub.region=us-east-1 \
            $MAVEN_PROFILE

        print_info "Deployment to CloudHub completed successfully!"
        ;;
esac

print_info "Process completed successfully!"
exit 0
