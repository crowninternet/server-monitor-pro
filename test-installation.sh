#!/bin/bash

# Uptime Monitor Pro - Installation Test Script
# This script tests the installation without actually installing

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
    echo -e "${BLUE}  Installation Test Results${NC}"
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

# Function to test XML syntax
test_xml_syntax() {
    local file="$1"
    local name="$2"
    
    print_status "Testing $name XML syntax..."
    
    if [ -f "$file" ]; then
        if xmllint --noout "$file" 2>/dev/null; then
            print_status "✅ $name XML syntax is valid"
        else
            print_error "❌ $name has XML syntax errors"
            return 1
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
    
    # Test package.json
    if ! test_json_syntax "package.json" "package.json"; then
        ((errors++))
    fi
    
    # Test launch agent template
    if ! test_xml_syntax "com.uptimemonitor.plist.template" "Launch agent template"; then
        ((errors++))
    fi
    
    # Test main API file exists
    print_status "Checking main API file..."
    if [ -f "uptime-monitor-api.js" ]; then
        print_status "✅ Main API file exists"
    else
        print_error "❌ Main API file not found"
        ((errors++))
    fi
    
    # Test main HTML file exists
    print_status "Checking main HTML file..."
    if [ -f "index.html" ]; then
        print_status "✅ Main HTML file exists"
    else
        print_error "❌ Main HTML file not found"
        ((errors++))
    fi
    
    # Test recovery HTML file exists
    print_status "Checking recovery HTML file..."
    if [ -f "recovery.html" ]; then
        print_status "✅ Recovery HTML file exists"
    else
        print_error "❌ Recovery HTML file not found"
        ((errors++))
    fi
    
    # Test documentation files
    print_status "Checking documentation files..."
    local doc_files=("README.md" "INSTALLATION.md" "SETUP.md")
    for doc_file in "${doc_files[@]}"; do
        if [ -f "$doc_file" ]; then
            print_status "✅ $doc_file exists"
        else
            print_warning "⚠️  $doc_file not found (optional)"
        fi
    done
    
    # Test system requirements
    print_status "Checking system requirements..."
    
    # Check macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "✅ Running on macOS"
    else
        print_error "❌ Not running on macOS"
        ((errors++))
    fi
    
    # Check if Homebrew is available or can be installed
    if command_exists brew; then
        print_status "✅ Homebrew is available"
    else
        print_warning "⚠️  Homebrew not found (will be installed by installer)"
    fi
    
    # Check if Node.js is available or can be installed
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_status "✅ Node.js is available: $NODE_VERSION"
    else
        print_warning "⚠️  Node.js not found (will be installed by installer)"
    fi
    
    # Summary
    echo ""
    if [ $errors -eq 0 ]; then
        print_status "🎉 All tests passed! Installation package is ready."
        echo ""
        echo "To install Uptime Monitor Pro:"
        echo "  chmod +x install.sh"
        echo "  ./install.sh"
    else
        print_error "❌ $errors test(s) failed. Please fix the issues before installation."
        exit 1
    fi
}

# Run tests
main "$@"
