# Sandbox Cluster Deployment Configuration

This is a copy of the k8s deployment configurations adapted for the sandbox cluster.

**🌐 See [SANDBOX-URLS.md](./SANDBOX-URLS.md) for all service URLs and DNS configuration.**

## Sandbox Environment

- **Cluster:** do-blr1-sandbox-cluster (DigitalOcean Bangalore)
- **Ingress IP:** 152.42.157.101
- **Domain Pattern:** sandbox-{service}.dotc3.com

## What Needs to Be Changed

### 1. Image Registry & Pull Secrets
- [ ] Update `imagePullSecrets` in all deployment.yaml files
- [ ] Create registry credentials in the sandbox cluster
- [ ] Verify image registry URLs are accessible from sandbox

### 2. Namespaces (if needed)
- [ ] Consider using different namespace names (e.g., `storefront-sandbox`)
- [ ] Update namespace references in all files

### 3. Ingress & Domains
- [ ] Update domain names in ingress.yaml files
- [ ] Update TLS certificate secret names
- [ ] Configure DNS to point to sandbox cluster
- [ ] Update any domain-specific nginx redirects/rewrites

### 4. Secrets & ConfigMaps
- [ ] Create secrets based on secret.example.yaml files
- [ ] Update configmap.yaml with sandbox-specific values:
  - API endpoints
  - Database connections
  - External service URLs
  - Environment variables

### 5. ClusterIssuer (cert-manager)
- [ ] Install cert-manager if not present in sandbox
- [ ] Update email in cluster-issuer.yaml if needed
- [ ] Verify Let's Encrypt can reach the sandbox cluster

### 6. Storage
- [ ] Verify storage classes exist in sandbox cluster
- [ ] Update PVC configurations if different storage is needed

### 7. Resources
- [ ] Adjust CPU/memory limits based on sandbox cluster capacity
- [ ] Adjust replica counts if needed

## Quick Start - Deployment Steps

### 1. Create Registry Secrets (Required First)

Run the helper script to create DigitalOcean registry credentials in all namespaces:

```bash
./create-registry-secrets.sh
```

This will prompt you for your DigitalOcean registry username and token, then create the `do-regcred` secret in all required namespaces.

### 2. Deploy Web-Admin (Automated)

Simply run the deployment script:

```bash
./deploy-web-admin.sh
```

This automated script will:
- ✅ Install cert-manager (if not present)
- ✅ Install nginx-ingress (if not present)
- ✅ Check registry credentials
- ✅ Deploy ClusterIssuer for Let's Encrypt
- ✅ Deploy web-admin (server + worker)
- ✅ Verify the deployment

### 3. Deploy Storefront (Automated)

Simply run the deployment script:

```bash
./deploy-storefront.sh
```

This automated script will:
- ✅ Install cert-manager (if not present)
- ✅ Install nginx-ingress (if not present)
- ✅ Check registry credentials
- ✅ Deploy storefront application
- ✅ Verify the deployment

### 4. Deploy Other Services (Manual)

After web-admin is deployed, you can deploy other services:

```bash
# Deploy prepwise-storefront
kubectl apply -k ./prepwise-storefront/

# Deploy storefront-stage
kubectl apply -k ./storefront-stage/

# Deploy c3-express
kubectl apply -k ./c3-express/
```

### 5. Verify All Deployments

```bash
# Check all pods
kubectl get pods -A

# Check all ingresses
kubectl get ingress -A

# Check all certificates
kubectl get certificates -A

# Check specific service
kubectl get all -n webadmin
kubectl logs -n webadmin deployment/webadmin-server
```

## Build & Deploy Scripts

For services that require building Docker images from source:

### Build and Deploy Web-Admin

```bash
./build-deploy-webadmin.sh
```

This script will:
- ✅ Build Docker image from source code
- ✅ Tag with git SHA and timestamp
- ✅ Push to DigitalOcean registry
- ✅ Update Kubernetes deployment (server + worker)
- ✅ Wait for rollout to complete

### Build and Deploy Storefront

```bash
./build-deploy-storefront.sh
```

This script will:
- ✅ Build Docker image from source code
- ✅ Tag with git SHA and timestamp
- ✅ Push to DigitalOcean registry
- ✅ Update Kubernetes deployment
- ✅ Wait for rollout to complete

### Build and Deploy C3 Express

```bash
./build-deploy-c3-express.sh
```

This script will:
- ✅ Build Docker image from source code
- ✅ Tag with git SHA and timestamp  
- ✅ Push to DigitalOcean registry
- ✅ Update Kubernetes deployment
- ✅ Wait for rollout to complete

**Note:** These scripts assume you have:
- Docker installed and running
- Access to DigitalOcean registry (`doctl registry login`)
- kubectl configured with sandbox cluster context

## Files Overview

### c3-express/
Backend Express service

### storefront/
Main storefront application (vsmartacademy.com)

### storefront-stage/
Staging environment for storefront

### prepwise-storefront/
Prepwise branded storefront

### web-admin/
Vendure admin panel (server + worker)

## Notes

- This is configured for the **sandbox** environment
- Original deployment files are in `/deployment/k8s/`
- Remember to update all hardcoded domain references
- Test each service independently before full deployment

