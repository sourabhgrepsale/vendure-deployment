set -euo pipefail

NAMESPACE="c3-express"
JOB_NAME="c3-express-order-full-fill-job-manual-$(date +%s)"
SECRET_NAME="google-service-account"
SERVICE_ACCOUNT_FILE="../c3-express/sardar123-f763351087be.json"

# Check if Google service account secret exists, if not create it
if ! kubectl -n "$NAMESPACE" get secret "$SECRET_NAME" &>/dev/null; then
  echo "Creating Google service account secret..."
  if [ -f "$SERVICE_ACCOUNT_FILE" ]; then
    kubectl -n "$NAMESPACE" create secret generic "$SECRET_NAME" \
      --from-file=sardar123-f763351087be.json="$SERVICE_ACCOUNT_FILE"
    echo "Secret created successfully"
  else
    echo "WARNING: Service account file not found at $SERVICE_ACCOUNT_FILE"
    echo "The job may fail if it requires Google Sheets access"
  fi
else
  echo "Google service account secret already exists"
fi

# Try to reuse the same image as the deployment; fallback to :latest
IMAGE="$(kubectl -n "$NAMESPACE" get deploy c3-express -o jsonpath='{.spec.template.spec.containers[?(@.name=="app")].image}' 2>/dev/null || true)"
if [ -z "$IMAGE" ]; then
  IMAGE="registry.digitalocean.com/grepvideos-server/c3-express:latest"
fi

echo "Creating Order Full Fill Job ${JOB_NAME} with image ${IMAGE} in namespace ${NAMESPACE}"
kubectl -n "$NAMESPACE" apply -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: ${NAMESPACE}
spec:
  template:
    spec:
      restartPolicy: Never
      imagePullSecrets:
        - name: do-regcred
      containers:
        - name: order-full-fill-job
          image: ${IMAGE}
          imagePullPolicy: IfNotPresent
          command: ["node", "./dist/order-full-fill.job.js"]
          envFrom:
            - configMapRef:
                name: c3-express-config
            - secretRef:
                name: c3-express-secrets
          volumeMounts:
            - name: google-service-account
              mountPath: /app/sardar123-f763351087be.json
              subPath: sardar123-f763351087be.json
              readOnly: true
      volumes:
        - name: google-service-account
          secret:
            secretName: ${SECRET_NAME}
YAML

echo "Waiting for Order Full Fill Job to complete..."
kubectl -n "$NAMESPACE" wait --for=condition=complete "job/${JOB_NAME}" --timeout=30m || true

POD="$(kubectl -n "$NAMESPACE" get pods -l job-name="${JOB_NAME}" -o jsonpath='{.items[0].metadata.name}')"
echo "Streaming logs from pod: ${POD}"
kubectl -n "$NAMESPACE" logs -f "$POD" || true

echo "Done. To cleanup: kubectl -n ${NAMESPACE} delete job ${JOB_NAME}"


