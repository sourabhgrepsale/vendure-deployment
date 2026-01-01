#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "=== Creating Registry Secrets for All Namespaces ==="
echo ""

# Check if credentials are provided as environment variables
if [ -z "$DO_REGISTRY_USER" ] || [ -z "$DO_REGISTRY_TOKEN" ]; then
    echo -e "${YELLOW}Please provide your DigitalOcean registry credentials:${NC}"
    read -p "Registry Username: " DO_REGISTRY_USER
    read -sp "Registry Token/Password: " DO_REGISTRY_TOKEN
    echo ""
fi

# List of namespaces that need the secret
NAMESPACES=("webadmin" "storefront" "storefront-stage" "c3-express" "prepwise-storefront")

for ns in "${NAMESPACES[@]}"; do
    echo -e "${YELLOW}Creating secret in namespace: $ns${NC}"
    
    # Create namespace if it doesn't exist
    kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
    
    # Delete secret if it exists (to update it)
    kubectl delete secret do-regcred -n "$ns" 2>/dev/null || true
    
    # Create the secret
    kubectl create secret docker-registry do-regcred \
        --docker-server=registry.digitalocean.com \
        --docker-username="$DO_REGISTRY_USER" \
        --docker-password="$DO_REGISTRY_TOKEN" \
        -n "$ns"
    
    echo -e "${GREEN}✓ Secret created in $ns${NC}"
done

echo ""
echo -e "${GREEN}=== All registry secrets created successfully! ===${NC}"
echo ""
echo "You can now run: ./deploy-web-admin.sh"

