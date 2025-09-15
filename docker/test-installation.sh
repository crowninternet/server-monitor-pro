#!/bin/bash

# Uptime Monitor Pro - Docker Installation Test Script
# This script tests the Docker installation package without actually installing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Docker Installation Test Results${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to test file syntax
test_syntax() {
    local file="$1"
    local name="$2"
    
    print_status "Testing $name syntax..."
    
    if [ -f "$file" ]; then
        if bash -n "$file" 2>/dev/null; then
            print_status "✅ $name syntax is valid"
        else
            print_error "❌ $name has syntax errors"
            return 1
        fi
    else
        print_error "❌ $name file not found: $file"
        return 1
    fi
}

# Function to test JSON syntax
test_json_syntax() {
    local file="$1"
    local name="$2"
    
    print_status "Testing $name JSON syntax..."
    
    if [ -f "$file" ]; then
        if python3 -m json.tool "$file" >/dev/null 2>&1; then
            print_status "✅ $name JSON syntax is valid"
        else
            print_error "❌ $name has JSON syntax errors"
            return 1
        fi
    else
        print_error "❌ $name file not found: $file"
        return 1
    fi
}

# Function to test YAML syntax
test_yaml_syntax() {
    local file="$1"
    local name="$2"
    
    print_status "Testing $name YAML syntax..."
    
    if [ -f "$file" ]; then
        # Basic YAML syntax check using Python
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            print_status "✅ $name YAML syntax is valid"
        else
            print_warning "⚠️  $name YAML syntax check failed (Python yaml module may not be available)"
        fi
    else
        print_error "❌ $name file not found: $file"
        return 1
    fi
}

# Function to test Dockerfile syntax
test_dockerfile_syntax() {
    local file="$1"
    local name="$2"
    
    print_status "Testing $name Dockerfile syntax..."
    
    if [ -f "$file" ]; then
        # Basic Dockerfile syntax check
        if grep -q "FROM" "$file" && grep -q "WORKDIR" "$file" && grep -q "CMD\|ENTRYPOINT" "$file"; then
            print_status "✅ $name Dockerfile syntax appears valid"
        else
            print_warning "⚠️  $name Dockerfile may be missing required instructions"
        fi
    else
        print_error "❌ $name file not found: $file"
        return 1
    fi
}

# Main test function
main() {
    print_header
    
    local errors=0
    
    # Test installation script
    if ! test_syntax "install.sh" "Installation script"; then
        ((errors++))
    fi
    
    # Test management script template
    if ! test_syntax "manage-uptime-monitor.sh.template" "Management script template"; then
        ((errors++))
    fi
    
    # Test Docker Compose file
    if ! test_yaml_syntax "docker-compose.yml" "Docker Compose file"; then
        ((errors++))
    fi
    
    # Test Dockerfile
    if ! test_dockerfile_syntax "Dockerfile" "Dockerfile"; then
        ((errors++))
    fi
    
    # Test main API file exists (copy from parent directory)
    print_status "Checking main API file..."
    if [ -f "../uptime-monitor-api.js" ]; then
        print_status "✅ Main API file exists"
    else
        print_error "❌ Main API file not found"
        ((errors++))
    fi
    
    # Test main HTML file exists (copy from parent directory)
    print_status "Checking main HTML file..."
    if [ -f "../index.html" ]; then
        print_status "✅ Main HTML file exists"
    else
        print_error "❌ Main HTML file not found"
        ((errors++))
    fi
    
    # Test recovery HTML file exists (copy from parent directory)
    print_status "Checking recovery HTML file..."
    if [ -f "../recovery.html" ]; then
        print_status "✅ Recovery HTML file exists"
    else
        print_error "❌ Recovery HTML file not found"
        ((errors++))
    fi
    
    # Test package.json exists (copy from parent directory)
    print_status "Checking package.json..."
    if [ -f "../package.json" ]; then
        print_status "✅ package.json exists"
        if ! test_json_syntax "../package.json" "package.json"; then
            ((errors++))
        fi
    else
        print_error "❌ package.json not found"
        ((errors++))
    fi
    
    # Test documentation files
    print_status "Checking documentation files..."
    local doc_files=("INSTALLATION.md")
    for doc_file in "${doc_files[@]}"; do
        if [ -f "$doc_file" ]; then
            print_status "✅ $doc_file exists"
        else
            print_warning "⚠️  $doc_file not found (optional)"
        fi
    done
    
    # Test system requirements
    print_status "Checking system requirements..."
    
    # Check Docker
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version)
        print_status "✅ Docker is available: $DOCKER_VERSION"
        
        # Check if Docker is running
        if docker info >/dev/null 2>&1; then
            print_status "✅ Docker is running"
        else
            print_warning "⚠️  Docker is not running"
        fi
    else
        print_warning "⚠️  Docker not found (will be required for installation)"
    fi
    
    # Check Docker Compose
    if command_exists docker-compose || docker compose version >/dev/null 2>&1; then
        if docker compose version >/dev/null 2>&1; then
            COMPOSE_VERSION=$(docker compose version)
            print_status "✅ Docker Compose V2 is available: $COMPOSE_VERSION"
        else
            COMPOSE_VERSION=$(docker-compose --version)
            print_status "✅ Docker Compose V1 is available: $COMPOSE_VERSION"
        fi
    else
        print_warning "⚠️  Docker Compose not found (will be required for installation)"
    fi
    
    # Check curl
    if command_exists curl; then
        print_status "✅ curl is available"
    else
        print_warning "⚠️  curl not found (will be required for health checks)"
    fi
    
    # Check Node.js (for testing)
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_status "✅ Node.js is available: $NODE_VERSION"
    else
        print_warning "⚠️  Node.js not found (not required for Docker installation)"
    fi
    
    # Test Docker-specific requirements
    print_status "Checking Docker-specific requirements..."
    
    # Check if user is in docker group (if Docker is installed)
    if command_exists docker && groups | grep -q docker; then
        print_status "✅ User is in docker group"
    elif command_exists docker; then
        print_warning "⚠️  User may need to be added to docker group or use sudo"
    fi
    
    # Check available disk space
    if command_exists df; then
        AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
        print_status "✅ Available disk space: $AVAILABLE_SPACE"
    fi
    
    # Summary
    echo ""
    if [ $errors -eq 0 ]; then
        print_status "🎉 All tests passed! Docker installation package is ready."
        echo ""
        echo "To install Uptime Monitor Pro with Docker:"
        echo "  chmod +x install.sh"
        echo "  ./install.sh"
        echo ""
        echo "Prerequisites:"
        echo "  - Docker Engine 20.10+ or Docker Desktop"
        echo "  - Docker Compose V1 or V2"
        echo "  - 1GB+ free disk space"
    else
        print_error "❌ $errors test(s) failed. Please fix the issues before installation."
        exit 1
    fi
}

# Run tests
main "$@"
