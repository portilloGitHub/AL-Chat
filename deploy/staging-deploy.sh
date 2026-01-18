#!/bin/bash
# Staging deployment script for AL-Chat
# Usage: ./deploy/staging-deploy.sh

set -e  # Exit on error

echo "========================================"
echo "  AL-Chat Staging Deployment"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] Docker is running${NC}"

# Check if staging compose file exists
if [ ! -f "docker-compose.staging.yml" ]; then
    echo -e "${RED}Error: docker-compose.staging.yml not found${NC}"
    exit 1
fi

# Stop existing staging containers
echo -e "${YELLOW}[INFO] Stopping existing staging containers...${NC}"
docker-compose -f docker-compose.staging.yml down || true

# Build and start staging containers
echo -e "${YELLOW}[INFO] Building and starting staging containers...${NC}"
docker-compose -f docker-compose.staging.yml build --no-cache
docker-compose -f docker-compose.staging.yml up -d

# Wait for health check
echo -e "${YELLOW}[INFO] Waiting for backend to be healthy...${NC}"
sleep 5

# Check health
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -f http://localhost:5001/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}[OK] Backend is healthy${NC}"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -e "${YELLOW}Waiting for backend... (attempt $ATTEMPT/$MAX_ATTEMPTS)${NC}"
    sleep 2
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo -e "${RED}Error: Backend health check failed${NC}"
    docker-compose -f docker-compose.staging.yml logs al-chat-backend
    exit 1
fi

# Show status
echo ""
echo -e "${GREEN}========================================"
echo "  Deployment Complete"
echo "========================================${NC}"
echo ""
echo "Staging backend is running on: http://localhost:5001"
echo ""
echo "To view logs: docker-compose -f docker-compose.staging.yml logs -f"
echo "To stop: docker-compose -f docker-compose.staging.yml down"
echo ""
