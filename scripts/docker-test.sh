#!/bin/bash
# Local Docker Build & Test Script
# Usage: ./scripts/docker-test.sh [api|web|all]

set -e

SERVICE=${1:-all}
DOCKER_BUILDKIT=1

echo "🐳 Yellow Book - Local Docker Build & Test"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function build_image() {
    local service=$1
    echo -e "${YELLOW}Building $service image...${NC}"
    docker build -f Dockerfile.$service -t yellowbook-$service:test .
    echo -e "${GREEN}✓ $service image built successfully${NC}"
    echo ""
}

function test_image() {
    local service=$1
    local port=$2
    
    echo -e "${YELLOW}Testing $service image...${NC}"
    
    # Clean up any existing container
    docker rm -f yellowbook-$service-test 2>/dev/null || true
    
    # Run container
    if [ "$service" == "api" ]; then
        docker run -d --name yellowbook-$service-test \
            -e DATABASE_URL="postgresql://test:test@localhost:5432/test" \
            -e PORT=$port \
            -p $port:$port \
            yellowbook-$service:test
    else
        docker run -d --name yellowbook-$service-test \
            -e NEXT_PUBLIC_API_URL="http://localhost:3333" \
            -e PORT=$port \
            -p $port:$port \
            yellowbook-$service:test
    fi
    
    # Wait for health check
    echo "Waiting for container to be healthy..."
    timeout 60 bash -c "until docker inspect --format='{{.State.Health.Status}}' yellowbook-$service-test | grep -q healthy; do sleep 2; done" || {
        echo -e "${RED}✗ Container failed to become healthy${NC}"
        docker logs yellowbook-$service-test
        docker rm -f yellowbook-$service-test
        exit 1
    }
    
    # Test endpoint
    echo "Testing HTTP endpoint..."
    if curl -f http://localhost:$port/ > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $service container is healthy and responding${NC}"
    else
        echo -e "${RED}✗ $service endpoint not responding${NC}"
        docker logs yellowbook-$service-test
        docker rm -f yellowbook-$service-test
        exit 1
    fi
    
    # Show container info
    echo ""
    echo "Container Details:"
    docker ps --filter name=yellowbook-$service-test
    echo ""
    
    # Cleanup
    docker rm -f yellowbook-$service-test
    echo -e "${GREEN}✓ $service test completed${NC}"
    echo ""
}

function build_and_test() {
    local service=$1
    local port=$2
    
    echo "=========================================="
    echo "Service: $service"
    echo "=========================================="
    echo ""
    
    build_image $service
    test_image $service $port
}

# Main execution
case $SERVICE in
    api)
        build_and_test "api" 3333
        ;;
    web)
        build_and_test "web" 3000
        ;;
    all)
        build_and_test "api" 3333
        build_and_test "web" 3000
        ;;
    *)
        echo "Usage: $0 [api|web|all]"
        exit 1
        ;;
esac

echo "=========================================="
echo -e "${GREEN}🎉 All tests passed!${NC}"
echo "=========================================="
echo ""
echo "Images ready:"
echo "  - yellowbook-api:test"
echo "  - yellowbook-web:test"
echo ""
echo "To run with docker-compose:"
echo "  docker-compose up -d"
echo ""
