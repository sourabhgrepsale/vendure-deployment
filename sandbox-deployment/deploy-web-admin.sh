#!/bin/bash
set -e

echo "=== Deploying Web-Admin to Sandbox Cluster ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Step 1: Check if cert-manager is installed
echo -e "${YELLOW}[1/6] Checking cert-manager...${NC}"
if kubectl get namespace cert-manager &> /dev/null; then
    CERT_MANAGER_PODS=$(kubectl get pods -n cert-manager --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CERT_MANAGER_PODS" -eq 0 ]; then
        echo "Installing cert-manager..."
        kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
        echo "Waiting for cert-manager to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
        kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
    else
        echo -e "${GREEN}✓ cert-manager already installed${NC}"
    fi
else
    echo "Installing cert-manager..."
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
    echo "Waiting for cert-manager to be ready..."
    sleep 10
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager -n cert-manager
    kubectl wait --for=condition=available --timeout=300s deployment/cert-manager-webhook -n cert-manager
fi

# Step 2: Check if nginx-ingress is installed
echo -e "${YELLOW}[2/6] Checking nginx-ingress...${NC}"
if kubectl get namespace ingress-nginx &> /dev/null; then
    INGRESS_PODS=$(kubectl get pods -n ingress-nginx --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$INGRESS_PODS" -eq 0 ]; then
        echo "Installing nginx-ingress..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/cloud/deploy.yaml
        echo "Waiting for nginx-ingress to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n ingress-nginx
    else
        echo -e "${GREEN}✓ nginx-ingress already installed${NC}"
    fi
else
    echo "Installing nginx-ingress..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/cloud/deploy.yaml
    echo "Waiting for nginx-ingress to be ready..."
    sleep 10
    kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n ingress-nginx
fi

# Step 3: Create registry secret if it doesn't exist
echo -e "${YELLOW}[3/6] Checking registry credentials...${NC}"
kubectl create namespace webadmin --dry-run=client -o yaml | kubectl apply -f -
if ! kubectl get secret do-regcred -n webadmin &> /dev/null; then
    echo -e "${RED}⚠ Registry secret 'do-regcred' not found in webadmin namespace${NC}"
    echo "Please create it manually with:"
    echo "  kubectl create secret docker-registry do-regcred \\"
    echo "    --docker-server=registry.digitalocean.com \\"
    echo "    --docker-username=<your-username> \\"
    echo "    --docker-password=<your-token> \\"
    echo "    -n webadmin"
    echo ""
    read -p "Press Enter to continue (or Ctrl+C to abort)..."
else
    echo -e "${GREEN}✓ Registry secret exists${NC}"
fi

# Step 4: Deploy ClusterIssuer
echo -e "${YELLOW}[4/6] Deploying ClusterIssuer...${NC}"
kubectl apply -f "$(dirname "$0")/web-admin/cluster-issuer.yaml"
echo -e "${GREEN}✓ ClusterIssuer deployed${NC}"

# Step 5: Deploy Web-Admin
echo -e "${YELLOW}[5/6] Deploying Web-Admin...${NC}"
kubectl apply -k "$(dirname "$0")/web-admin/"
echo -e "${GREEN}✓ Web-Admin deployed${NC}"

# Step 6: Verify deployment
echo -e "${YELLOW}[6/6] Verifying deployment...${NC}"
echo ""
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/webadmin-server -n webadmin
kubectl wait --for=condition=available --timeout=300s deployment/webadmin-worker -n webadmin

echo ""
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Resources in webadmin namespace:"
kubectl get all -n webadmin
echo ""
echo "Ingress configuration:"
kubectl get ingress -n webadmin
echo ""
echo "Certificates:"
kubectl get certificates -n webadmin
echo ""
echo -e "${GREEN}Web-Admin is now deployed!${NC}"
echo ""
echo "To view logs:"
echo "  kubectl logs -n webadmin deployment/webadmin-server"
echo "  kubectl logs -n webadmin deployment/webadmin-worker"

