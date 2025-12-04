set -euo pipefail

# Paths and registry
cd /Users/sourabh/vendure
REGISTRY="registry.digitalocean.com/grepvideos-server"
IMAGE="storefront"

# Tag format: <sha8>-<yymmddHHMMSS>-amd64 (matches existing convention)
SHA="$(git rev-parse --short=8 HEAD || echo "nogit")"
STAMP="$(date -u +'%y%m%d%H%M%S')"
TAG="${SHA}-${STAMP}-amd64"
FULL="${REGISTRY}/${IMAGE}:${TAG}"

echo "Building image: ${FULL}"
docker build --platform linux/amd64 -t "${FULL}" /Users/sourabh/vendure/storefront

echo "Pushing image: ${FULL}"
# Ensure you're logged in: doctl registry login  (or: docker login registry.digitalocean.com)
docker push "${FULL}"

echo "Updating Kubernetes deployment to ${FULL}"
kubectl -n storefront set image deployment/storefront app="${FULL}"

echo "Waiting for rollout..."
kubectl -n storefront rollout status deployment/storefront

echo "Deployment updated to ${FULL}"
kubectl -n storefront get pods -l app=storefront -o wide