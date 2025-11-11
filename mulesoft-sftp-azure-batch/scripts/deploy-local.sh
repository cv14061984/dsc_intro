#!/bin/bash

###############################################################################
# Local Deployment Script for SFTP to Azure Batch Integration
# Usage: ./scripts/deploy-local.sh [dev|qa|prod]
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
echo -e "${GREEN}MuleSoft Local Deployment Script${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Validate environment
if [[ ! "$ENV" =~ ^(dev|qa|prod)$ ]]; then
    echo -e "${RED}Error: Invalid environment '$ENV'${NC}"
    echo "Usage: $0 [dev|qa|prod]"
    exit 1
fi

echo -e "${YELLOW}Environment: $ENV${NC}"
echo ""

# Check if MULE_HOME is set
if [ -z "$MULE_HOME" ]; then
    echo -e "${RED}Error: MULE_HOME environment variable is not set${NC}"
    echo "Please set MULE_HOME to your Mule runtime directory"
    exit 1
fi

echo -e "${YELLOW}MULE_HOME: $MULE_HOME${NC}"
echo ""

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}Error: Maven is not installed${NC}"
    exit 1
fi

echo -e "${GREEN}Building application...${NC}"
mvn clean package -DskipTests -Denv=$ENV

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Build successful!${NC}"
else
    echo -e "${RED}Build failed!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Deploying to local Mule runtime...${NC}"

# Get the artifact name
ARTIFACT_NAME=$(ls target/*.jar | head -n 1)

if [ -z "$ARTIFACT_NAME" ]; then
    echo -e "${RED}Error: No deployable artifact found in target directory${NC}"
    exit 1
fi

# Copy to Mule apps directory
cp "$ARTIFACT_NAME" "$MULE_HOME/apps/"

echo -e "${GREEN}Deployment successful!${NC}"
echo ""
echo -e "${YELLOW}Application deployed to: $MULE_HOME/apps/${NC}"
echo -e "${YELLOW}Monitor logs at: $MULE_HOME/logs/${NC}"
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Deployment Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
