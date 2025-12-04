set -euo pipefail

NAMESPACE="c3-express"
JOB_NAME="c3-express-order-job-manual-$(date +%s)"

# Try to reuse the same image as the deployment; fallback to :latest
IMAGE="$(kubectl -n "$NAMESPACE" get deploy c3-express -o jsonpath='{.spec.template.spec.containers[?(@.name=="app")].image}' 2>/dev/null || true)"
if [ -z "$IMAGE" ]; then
  IMAGE="registry.digitalocean.com/grepvideos-server/c3-express:latest"
fi

echo "Creating Order Job ${JOB_NAME} with image ${IMAGE} in namespace ${NAMESPACE}"
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
        - name: order-job
          image: ${IMAGE}
          imagePullPolicy: IfNotPresent
          command: ["node", "./dist/order-job.js"]
          envFrom:
            - configMapRef:
                name: c3-express-config
            - secretRef:
                name: c3-express-secrets
YAML

echo "Waiting for Order Job to complete..."
kubectl -n "$NAMESPACE" wait --for=condition=complete "job/${JOB_NAME}" --timeout=30m || true

POD="$(kubectl -n "$NAMESPACE" get pods -l job-name="${JOB_NAME}" -o jsonpath='{.items[0].metadata.name}')"
echo "Streaming logs from pod: ${POD}"
kubectl -n "$NAMESPACE" logs -f "$POD" || true

echo "Done. To cleanup: kubectl -n ${NAMESPACE} delete job ${JOB_NAME}"

