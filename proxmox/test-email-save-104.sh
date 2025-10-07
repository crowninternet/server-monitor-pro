#!/bin/bash

# Test Email Config Save for Container 104
# Run from Proxmox HOST
# Tests saving email configuration directly via API

CONTAINER_ID=104

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

echo "========================================"
echo "  Test Email Config Save"
echo "========================================"
echo ""

print_info "This will help you save your SendGrid configuration"
echo ""

# Get user input
read -p "Enter your SendGrid API Key (starts with SG.): " API_KEY
read -p "Enter FROM email address (must be verified in SendGrid): " FROM_EMAIL
read -p "Enter TO email address (where alerts will be sent): " TO_EMAIL
read -p "Enable email alerts? (y/n): " ENABLE_EMAIL

if [[ $ENABLE_EMAIL =~ ^[Yy]$ ]]; then
    EMAIL_ENABLED="true"
else
    EMAIL_ENABLED="false"
fi

echo ""
print_info "Saving configuration to container 104..."
echo ""

# Build JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "sendgridApiKey": "$API_KEY",
  "emailFrom": "$FROM_EMAIL",
  "emailTo": "$TO_EMAIL",
  "emailEnabled": $EMAIL_ENABLED
}
EOF
)

# Send request
RESPONSE=$(pct exec $CONTAINER_ID -- curl -s -X POST http://localhost:3000/api/email-config \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

echo "Response:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if successful
if echo "$RESPONSE" | grep -q '"success":true'; then
    print_success "Email configuration saved successfully!"
    echo ""
    
    # Offer to test
    read -p "Would you like to send a test email? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Sending test email..."
        TEST_RESPONSE=$(pct exec $CONTAINER_ID -- curl -s -X POST http://localhost:3000/api/test-email)
        echo "$TEST_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TEST_RESPONSE"
        echo ""
        
        if echo "$TEST_RESPONSE" | grep -q '"success":true'; then
            print_success "Test email sent! Check your inbox at $TO_EMAIL"
        else
            print_error "Test email failed. Check the error above."
        fi
    fi
else
    print_error "Failed to save configuration"
    echo ""
    print_info "Common issues:"
    echo "  - SendGrid API key must start with 'SG.'"
    echo "  - FROM email must be verified in your SendGrid account"
    echo "  - Both FROM and TO emails are required"
    echo ""
fi

echo ""
print_info "You can now view your config in the web interface"
echo "  URL: http://YOUR_PROXMOX_IP:3000"
echo ""

