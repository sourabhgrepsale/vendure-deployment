# Sandbox Cluster URLs

All services in the sandbox cluster use the `dotc3.com` domain with a `sandbox-` prefix.

## Service URLs

| Service | URL | Description |
|---------|-----|-------------|
| **Web Admin** | https://sandbox-vnd.dotc3.com | Vendure admin panel (Vendure backend) |
| **Storefront** | https://sandbox-storefront.dotc3.com | Main VSmart Academy storefront |
| **Storefront Stage** | https://sandbox-storefront-stage.dotc3.com | Staging environment for storefront |
| **Prepwise Storefront** | https://sandbox-prepwise.dotc3.com | Prepwise branded storefront |
| **C3 Express (AppWallah)** | https://staging.appwallah.com | Backend Express API service |
| **C3 Express (DotC3)** | https://sandbox-c3.dotc3.com | Backend Express API service (alternate) |

## DNS Configuration

Point all these domains to your nginx-ingress external IP:

**External IP:** `152.42.157.101` (from nginx-ingress-controller)

### DNS Records to Create:

```
Type: A
Name: sandbox-vnd
Value: 152.42.157.101
TTL: 300

Type: A
Name: sandbox-storefront
Value: 152.42.157.101
TTL: 300

Type: A
Name: sandbox-storefront-stage
Value: 152.42.157.101
TTL: 300

Type: A
Name: sandbox-prepwise
Value: 152.42.157.101
TTL: 300

Type: A
Name: sandbox-c3
Value: 152.42.157.101
TTL: 300

Type: A
Name: staging.appwallah.com (full domain)
Value: 152.42.157.101
TTL: 300
```

## SSL Certificates

All domains are configured with Let's Encrypt automatic SSL certificates via cert-manager.

Certificates will be automatically issued after:
1. DNS records are pointing to the correct IP
2. The ingress resources are deployed
3. cert-manager can reach your domains via HTTP-01 challenge

## Notes

- All production-specific redirects have been removed from sandbox
- No student login subdomain in sandbox
- Simplified configuration for testing and development

