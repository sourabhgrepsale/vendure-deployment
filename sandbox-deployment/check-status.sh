#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Sandbox Cluster Status ===${NC}"
echo ""

# Check cluster connection
echo -e "${YELLOW}Cluster Info:${NC}"
kubectl cluster-info | head -2
echo ""

# Check cert-manager
echo -e "${YELLOW}cert-manager:${NC}"
if kubectl get namespace cert-manager &> /dev/null; then
    CERT_PODS=$(kubectl get pods -n cert-manager --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$CERT_PODS" -gt 0 ]; then
        echo -e "${GREEN}✓ Installed and running ($CERT_PODS pods)${NC}"
    else
        echo -e "${RED}✗ Installed but not running${NC}"
    fi
else
    echo -e "${RED}✗ Not installed${NC}"
fi

# Check nginx-ingress
echo -e "${YELLOW}nginx-ingress:${NC}"
if kubectl get namespace ingress-nginx &> /dev/null; then
    INGRESS_PODS=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | grep -c Running || echo "0")
    if [ "$INGRESS_PODS" -gt 0 ]; then
        echo -e "${GREEN}✓ Installed and running ($INGRESS_PODS pods)${NC}"
        # Get external IP
        EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$EXTERNAL_IP" ]; then
            echo -e "  External IP: ${GREEN}$EXTERNAL_IP${NC}"
        fi
    else
        echo -e "${RED}✗ Installed but not running${NC}"
    fi
else
    echo -e "${RED}✗ Not installed${NC}"
fi

echo ""
echo -e "${BLUE}=== Application Deployments ===${NC}"
echo ""

# Function to check namespace status
check_namespace() {
    local ns=$1
    local app_name=$2
    
    if kubectl get namespace "$ns" &> /dev/null; then
        echo -e "${YELLOW}$app_name (namespace: $ns):${NC}"
        
        # Check for registry secret
        if kubectl get secret do-regcred -n "$ns" &> /dev/null 2>&1; then
            echo -e "  Registry Secret: ${GREEN}✓ exists${NC}"
        else
            echo -e "  Registry Secret: ${RED}✗ missing${NC}"
        fi
        
        # Check deployments
        DEPLOYMENTS=$(kubectl get deployments -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
        if [ "$DEPLOYMENTS" -gt 0 ]; then
            kubectl get deployments -n "$ns" --no-headers 2>/dev/null | while read name ready uptodate available age; do
                if [ "$ready" = "$available" ] && [ "$available" != "0" ]; then
                    echo -e "  Deployment $name: ${GREEN}✓ $ready${NC}"
                else
                    echo -e "  Deployment $name: ${YELLOW}⚠ $ready${NC}"
                fi
            done
        else
            echo -e "  Deployments: ${RED}✗ none${NC}"
        fi
        
        # Check pods
        RUNNING_PODS=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | grep -c Running || echo "0")
        TOTAL_PODS=$(kubectl get pods -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
        if [ "$TOTAL_PODS" -gt 0 ]; then
            if [ "$RUNNING_PODS" = "$TOTAL_PODS" ]; then
                echo -e "  Pods: ${GREEN}✓ $RUNNING_PODS/$TOTAL_PODS running${NC}"
            else
                echo -e "  Pods: ${YELLOW}⚠ $RUNNING_PODS/$TOTAL_PODS running${NC}"
            fi
        fi
        
        # Check ingress
        if kubectl get ingress -n "$ns" &> /dev/null 2>&1; then
            INGRESS_COUNT=$(kubectl get ingress -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
            if [ "$INGRESS_COUNT" -gt 0 ]; then
                echo -e "  Ingress: ${GREEN}✓ $INGRESS_COUNT configured${NC}"
            fi
        fi
        
        echo ""
    else
        echo -e "${YELLOW}$app_name:${NC} ${RED}✗ namespace not created${NC}"
        echo ""
    fi
}

# Check each service
check_namespace "webadmin" "Web Admin"
check_namespace "storefront" "Storefront"
check_namespace "storefront-stage" "Storefront Stage"
check_namespace "prepwise-storefront" "Prepwise Storefront"
check_namespace "c3-express" "C3 Express"

echo -e "${BLUE}=== Certificates ===${NC}"
kubectl get certificates -A 2>/dev/null || echo "No certificates found"
echo ""

echo -e "${BLUE}=== Ingress Rules ===${NC}"
kubectl get ingress -A 2>/dev/null || echo "No ingress rules found"
echo ""

echo -e "${GREEN}Status check complete!${NC}"

