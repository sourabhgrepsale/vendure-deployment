set -euo pipefail

# Paths and registry
cd /Users/sourabh/vendure
REGISTRY="registry.digitalocean.com/grepvideos-server"
IMAGE="webadmin"
APP_DIR="/Users/sourabh/vendure/web-admin"

# Tag format: <sha8>-<yymmddHHMMSS>-amd64 (matches existing convention)
SHA="$(git -C "$APP_DIR" rev-parse --short=8 HEAD || echo "nogit")"
STAMP="$(date -u +'%y%m%d%H%M%S')"
TAG="${SHA}-${STAMP}-amd64"
FULL="${REGISTRY}/${IMAGE}:${TAG}"

echo "Building image: ${FULL}"
docker build --no-cache --platform linux/amd64 -t "${FULL}" "${APP_DIR}"

echo "Pushing image: ${FULL}"
# Ensure you're logged in: doctl registry login  (or: docker login registry.digitalocean.com)
docker push "${FULL}"

echo "Updating Kubernetes deployments to ${FULL}"
kubectl -n webadmin set image deployment/webadmin-server server="${FULL}"
kubectl -n webadmin set image deployment/webadmin-worker worker="${FULL}"

echo "Waiting for rollouts..."
kubectl -n webadmin rollout status deployment/webadmin-server
kubectl -n webadmin rollout status deployment/webadmin-worker

echo "Deployments updated to ${FULL}"
kubectl -n webadmin get pods -l app=webadmin-server -o wide || true
kubectl -n webadmin get pods -l app=webadmin-worker -o wide || true


