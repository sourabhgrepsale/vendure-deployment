set -euo pipefail

# Paths and registry
cd /Users/sourabh/vendure
REGISTRY="registry.digitalocean.com/grepvideos-server"
IMAGE="c3-express"
APP_DIR="/Users/sourabh/vendure/c3-express"

# Tag format: <sha8>-<yymmddHHMMSS>-amd64 (matches existing convention)
SHA="$(git -C "$APP_DIR" rev-parse --short=8 HEAD || echo "nogit")"
STAMP="$(date -u +'%y%m%d%H%M%S')"
TAG="${SHA}-${STAMP}-amd64"
FULL="${REGISTRY}/${IMAGE}:${TAG}"

echo "Building image: ${FULL}"
docker build --platform linux/amd64 -t "${FULL}" "${APP_DIR}"

echo "Pushing image: ${FULL}"
# Ensure you're logged in: doctl registry login  (or: docker login registry.digitalocean.com)
docker push "${FULL}"

echo "Tagging and pushing :latest"
LATEST="${REGISTRY}/${IMAGE}:latest"
docker tag "${FULL}" "${LATEST}"
docker push "${LATEST}"

echo "Updating Kubernetes deployment to ${FULL}"
kubectl -n c3-express set image deployment/c3-express app="${FULL}"
# CronJob removed from kustomization; skipping image update for cronjob

echo "Waiting for rollout..."
kubectl -n c3-express rollout status deployment/c3-express
kubectl -n c3-express get cronjob c3-express-job -o wide || true

echo "Deployment updated to ${FULL}"
kubectl -n c3-express get pods -l app=c3-express -o wide || true


