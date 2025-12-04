#!/usr/bin/env bash
set -euo pipefail

# Build and deploy the exportOrdersToSheets Google Cloud Function (Gen 2)
# Usage (env vars):
#   PROJECT_ID=your-project REGION=us-central1 \
#   MONGODB_URI='mongodb+srv://...' MONGODB_DB_NAME='c3' \
#   FUNCTION_NAME=exportOrdersToSheets \
#   ./deployment/build-deploy-export-orders-to-sheets.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FUNCTION_DIR="$REPO_ROOT/cloud-functions/export-orders-to-sheets"

PROJECT_ID="${PROJECT_ID:-}"
if [[ -z "${PROJECT_ID}" ]]; then
  PROJECT_ID="$(gcloud config get-value project 2>/dev/null || true)"
fi
if [[ -z "${PROJECT_ID}" ]]; then
  echo "[ERROR] PROJECT_ID not set and no default gcloud project configured." >&2
  exit 1
fi

REGION="${REGION:-us-central1}"
RUNTIME="${RUNTIME:-nodejs18}"
FUNCTION_NAME="${FUNCTION_NAME:-exportOrdersToSheets}"
ENTRY_POINT="${ENTRY_POINT:-exportOrdersToSheets}"
SERVICE_ACCOUNT="${SERVICE_ACCOUNT:-sheet-processor@grepvideos-server.iam.gserviceaccount.com}"

# Required environment variables for the function (defaults can be overridden)
# NOTE: These defaults mirror c3-express prod settings; override in your env if different
MONGODB_URI="${MONGODB_URI:-mongodb+srv://root:hilOiamR77L11O0F@grepvideos-prod-pri.kcmsl.mongodb.net?retryWrites=true&w=majority}"
MONGODB_DB_NAME="${MONGODB_DB_NAME:-c3-express-prod}"
ORDERS_COLLECTION="${ORDERS_COLLECTION:-orders}"
BUSINESSES_COLLECTION="${BUSINESSES_COLLECTION:-businesses}"
PRODUCTS_COLLECTION="${PRODUCTS_COLLECTION:-products}"

# VPC connector settings (use your existing connector)
VPC_CONNECTOR="${VPC_CONNECTOR:-scheduler-vpc}"
EGRESS_SETTINGS="${EGRESS_SETTINGS:-all}"

if [[ -z "${MONGODB_URI}" ]]; then
  echo "[ERROR] MONGODB_URI resolved to empty string." >&2
  exit 1
fi
if [[ -z "${MONGODB_DB_NAME}" ]]; then
  echo "[ERROR] MONGODB_DB_NAME resolved to empty string." >&2
  exit 1
fi

echo "[INFO] Project: ${PROJECT_ID}"
echo "[INFO] Region: ${REGION}"
echo "[INFO] Function: ${FUNCTION_NAME} (${ENTRY_POINT})"
echo "[INFO] Function dir: ${FUNCTION_DIR}"
echo "[INFO] VPC Connector: ${VPC_CONNECTOR} (egress=${EGRESS_SETTINGS})"
echo "[INFO] Service Account: ${SERVICE_ACCOUNT}"

pushd "${FUNCTION_DIR}" >/dev/null

echo "[INFO] Installing dependencies..."
if command -v npm >/dev/null 2>&1; then
  if [[ -f package-lock.json ]]; then
    npm ci
  else
    npm install
  fi
else
  echo "[ERROR] npm not found. Please install Node.js/npm." >&2
  exit 1
fi

echo "[INFO] Building TypeScript..."
npm run build

echo "[INFO] Deploying Cloud Function (Gen 2)..."
gcloud functions deploy "${FUNCTION_NAME}" \
  --gen2 \
  --project "${PROJECT_ID}" \
  --region "${REGION}" \
  --runtime "${RUNTIME}" \
  --entry-point "${ENTRY_POINT}" \
  --trigger-http \
  --allow-unauthenticated \
  --source "${FUNCTION_DIR}" \
  --set-env-vars "MONGODB_URI=${MONGODB_URI},MONGODB_DB_NAME=${MONGODB_DB_NAME},ORDERS_COLLECTION=${ORDERS_COLLECTION},BUSINESSES_COLLECTION=${BUSINESSES_COLLECTION},PRODUCTS_COLLECTION=${PRODUCTS_COLLECTION}" \
  --vpc-connector "${VPC_CONNECTOR}" \
  --egress-settings "${EGRESS_SETTINGS}" \
  --service-account "${SERVICE_ACCOUNT}"

popd >/dev/null

FUNCTION_URL="$(gcloud functions describe "${FUNCTION_NAME}" --region "${REGION}" --format='value(serviceConfig.uri)')"
echo "[SUCCESS] Deployment complete."
echo "[INFO] Function URL: ${FUNCTION_URL}"


