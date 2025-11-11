#!/bin/bash

###############################################################################
# Test Runner Script for SFTP to Azure Batch Integration
# Usage: ./scripts/run-tests.sh
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}MuleSoft Test Runner${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Check if Maven is installed
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}Error: Maven is not installed${NC}"
    exit 1
fi

echo -e "${YELLOW}Running MUnit tests...${NC}"
echo ""

mvn clean test -Denv=dev

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}All Tests Passed!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
    echo -e "${YELLOW}Test reports available at:${NC}"
    echo -e "${YELLOW}target/surefire-reports/${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}=====================================${NC}"
    echo -e "${RED}Tests Failed!${NC}"
    echo -e "${RED}=====================================${NC}"
    echo ""
    exit 1
fi
