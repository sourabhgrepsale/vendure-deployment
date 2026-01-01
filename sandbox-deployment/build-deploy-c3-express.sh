#!/bin/bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Paths and registry
cd /Users/sourabh/vendure
REGISTRY="registry.digitalocean.com/grepvideos-server"
IMAGE="c3-express"
APP_DIR="/Users/sourabh/vendure/c3-express"
NAMESPACE="c3-express"
CONTEXT="do-blr1-sandbox-cluster"

# Tag format: <sha8>-<yymmddHHMMSS>-amd64 (matches existing convention)
SHA="$(git -C "$APP_DIR" rev-parse --short=8 HEAD || echo "nogit")"
STAMP="$(date -u +'%y%m%d%H%M%S')"
TAG="${SHA}-${STAMP}-amd64"
FULL="${REGISTRY}/${IMAGE}:${TAG}"

echo -e "${YELLOW}=== Building and Deploying C3 Express to Sandbox Cluster ===${NC}"
echo ""

# Check and switch to sandbox context
CURRENT_CONTEXT=$(kubectl config current-context)
if [ "$CURRENT_CONTEXT" != "$CONTEXT" ]; then
    echo -e "${YELLOW}Switching kubectl context from $CURRENT_CONTEXT to $CONTEXT${NC}"
    kubectl config use-context "$CONTEXT"
else
    echo -e "${GREEN}✓ Already using context: $CONTEXT${NC}"
fi
echo ""

# Build image
echo -e "${YELLOW}[1/4] Building Docker image: ${FULL}${NC}"
docker build --no-cache --platform linux/amd64 -t "${FULL}" "${APP_DIR}"
echo -e "${GREEN}✓ Image built successfully${NC}"
echo ""

# Push image
echo -e "${YELLOW}[2/4] Pushing image to registry${NC}"
# Ensure you're logged in: doctl registry login  (or: docker login registry.digitalocean.com)
docker push "${FULL}"
echo -e "${GREEN}✓ Image pushed successfully${NC}"
echo ""

# Update deployment
echo -e "${YELLOW}[3/4] Updating Kubernetes deployment to ${FULL}${NC}"
kubectl -n "${NAMESPACE}" set image deployment/c3-express app="${FULL}"
echo -e "${GREEN}✓ Deployment updated${NC}"
echo ""

# Wait for rollout
echo -e "${YELLOW}[4/4] Waiting for rollout to complete...${NC}"
kubectl -n "${NAMESPACE}" rollout status deployment/c3-express
echo -e "${GREEN}✓ Rollout completed${NC}"
echo ""

# Show final status
echo -e "${GREEN}=== Deployment Complete! ===${NC}"
echo ""
echo "Image deployed: ${FULL}"
echo ""
echo "C3 Express pods:"
kubectl -n "${NAMESPACE}" get pods -l app=c3-express -o wide || true
echo ""
echo -e "${GREEN}C3 Express is now running in sandbox cluster!${NC}"
echo ""
echo "To view logs:"
echo "  kubectl logs -n ${NAMESPACE} deployment/c3-express -f"
echo ""
echo "To check ingress:"
echo "  kubectl get ingress -n ${NAMESPACE}"







