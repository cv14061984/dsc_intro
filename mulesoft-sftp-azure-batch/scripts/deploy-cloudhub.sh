#!/bin/bash

###############################################################################
# CloudHub Deployment Script for SFTP to Azure Batch Integration
# Usage: ./scripts/deploy-cloudhub.sh [dev|qa|prod]
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default environment
ENV=${1:-dev}

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}MuleSoft CloudHub Deployment Script${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Validate environment
if [[ ! "$ENV" =~ ^(dev|qa|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment '$ENV'${NC}"
    echo "Usage: $0 [dev|qa|prod]"
    exit 1
fi

echo -e "${YELLOW}Target Environment: $ENV${NC}"
echo ""

# Check for required environment variables
if [ -z "$ANYPOINT_USERNAME" ]; then
    echo -e "${RED}Error: ANYPOINT_USERNAME not set${NC}"
    echo "Set your Anypoint Platform username: export ANYPOINT_USERNAME=your_username"
    exit 1
fi

if [ -z "$ANYPOINT_PASSWORD" ]; then
    echo -e "${RED}Error: ANYPOINT_PASSWORD not set${NC}"
    echo "Set your Anypoint Platform password: export ANYPOINT_PASSWORD=your_password"
    exit 1
fi

# Set environment-specific configurations
case $ENV in
    dev)
        APP_NAME="sftp-azure-batch-dev"
        CLOUDHUB_ENV="Development"
        REGION="us-east-2"
        WORKER_TYPE="MICRO"
        WORKERS="1"
        ;;
    qa)
        APP_NAME="sftp-azure-batch-qa"
        CLOUDHUB_ENV="QA"
        REGION="us-east-2"
        WORKER_TYPE="MICRO"
        WORKERS="1"
        ;;
    prod)
        APP_NAME="sftp-azure-batch-prod"
        CLOUDHUB_ENV="Production"
        REGION="us-east-2"
        WORKER_TYPE="SMALL"
        WORKERS="2"
        ;;
esac

echo -e "${YELLOW}Application Name: $APP_NAME${NC}"
echo -e "${YELLOW}CloudHub Environment: $CLOUDHUB_ENV${NC}"
echo -e "${YELLOW}Region: $REGION${NC}"
echo -e "${YELLOW}Worker Type: $WORKER_TYPE${NC}"
echo -e "${YELLOW}Number of Workers: $WORKERS${NC}"
echo ""

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}Error: Maven is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}Building and deploying to CloudHub...${NC}"
echo ""

mvn clean deploy -DmuleDeploy \
    -Danypoint.username="$ANYPOINT_USERNAME" \
    -Danypoint.password="$ANYPOINT_PASSWORD" \
    -Denv=$ENV \
    -DapplicationName="$APP_NAME" \
    -Denvironment="$CLOUDHUB_ENV" \
    -Dregion="$REGION" \
    -DworkerType="$WORKER_TYPE" \
    -Dworkers="$WORKERS" \
    -DmuleVersion="4.4.0" \
    -DobjectStoreV2="true"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "${YELLOW}Application URL: https://$APP_NAME.cloudhub.io${NC}"
    echo -e "${YELLOW}View in Runtime Manager: https://anypoint.mulesoft.com${NC}"
    echo ""
else
    echo -e "${RED}Deployment failed!${NC}"
    exit 1
fi
