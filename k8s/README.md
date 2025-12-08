# Kubernetes Manifests for Yellowbook

This directory contains all Kubernetes manifest files for deploying the Yellowbook application to AWS EKS.

## Files Overview

### Core Resources

- **`namespace.yaml`** - Creates the `yellowbooks` namespace for all resources
- **`configmap.yaml`** - Application configuration (non-sensitive)
- **`secret.yaml`** - Sensitive configuration (database credentials, JWT secrets)

### Database

- **`postgres-deployment.yaml`** - PostgreSQL database with persistent storage
  - Deployment with PostgreSQL 15
  - PersistentVolumeClaim (10Gi)
  - Service (ClusterIP)
  - ConfigMap and Secret for DB credentials

### Application Components

- **`api-deployment.yaml`** - Backend API server
  - Deployment (2-10 replicas with HPA)
  - Service (ClusterIP on port 80)
  - Health checks (liveness/readiness probes)
  - Resource limits

- **`web-deployment.yaml`** - Frontend Next.js application
  - Deployment (2-10 replicas with HPA)
  - Service (ClusterIP on port 80)
  - Health checks
  - Resource limits

### Jobs

- **`migration-job.yaml`** - Database migration job
  - Runs Prisma migrations before app deployment
  - Init container waits for PostgreSQL
  - Auto-cleanup after completion (TTL: 5 minutes)

### Scaling & Routing

- **`hpa.yaml`** - Horizontal Pod Autoscalers
  - Auto-scales API and Web deployments
  - Based on CPU (70%) and memory (80%) metrics
  - Min: 2 replicas, Max: 10 replicas

- **`ingress.yaml`** - AWS Application Load Balancer Ingress
  - Routes traffic to web and API services
  - SSL/TLS termination with ACM certificate
  - HTTP to HTTPS redirect
  - Route53 integration via External DNS

### Access Control

- **`aws-auth.yaml`** - AWS IAM to Kubernetes RBAC mapping
  - Maps IAM roles to Kubernetes users
  - Grants GitHub Actions deployment access
  - Configures node instance role

- **`rbac.yaml`** - Kubernetes RBAC resources
  - ServiceAccount for deployment
  - Role with namespace-scoped permissions
  - RoleBinding
  - ClusterRole for cluster-wide read access

### Build Tool

- **`kustomization.yaml`** - Kustomize configuration
  - Simplifies multi-manifest deployment
  - Common labels
  - Image name transformations

## Deployment Order

For proper deployment, apply manifests in this order:

```bash
# 1. Namespace
kubectl apply -f namespace.yaml

# 2. Configuration
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# 3. Database
kubectl apply -f postgres-deployment.yaml
kubectl wait --for=condition=ready pod -l app=postgres -n yellowbooks --timeout=300s

# 4. Migration
kubectl apply -f migration-job.yaml
kubectl wait --for=condition=complete job/yellowbook-migration -n yellowbooks --timeout=300s

# 5. Applications
kubectl apply -f api-deployment.yaml
kubectl apply -f web-deployment.yaml

# 6. Scaling & Routing
kubectl apply -f hpa.yaml
kubectl apply -f ingress.yaml

# 7. Access Control (if needed)
kubectl apply -f aws-auth.yaml
kubectl apply -f rbac.yaml
```

Or use Kustomize for simplified deployment:

```bash
# Deploy all resources
kubectl apply -k .

# Update image tags
kustomize edit set image tuguu04133/yellowbook-api=123456789.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:v2
kubectl apply -k .
```

## Configuration Checklist

Before deploying, update these files:

### `secret.yaml`
- [ ] Update `DATABASE_URL` with your PostgreSQL credentials
- [ ] Update `JWT_SECRET` with a secure random string

### `configmap.yaml`
- [ ] Update `NEXT_PUBLIC_API_URL` with your API domain
- [ ] Verify `PORT` and `API_PORT` match your application

### `ingress.yaml`
- [ ] Replace `ACCOUNT_ID` and `CERTIFICATE_ID` in certificate ARN
- [ ] Replace `example.com` with your actual domain
- [ ] Update both `yellowbook.example.com` and `api.yellowbook.example.com`

### `aws-auth.yaml`
- [ ] Replace `ACCOUNT_ID` with your AWS Account ID
- [ ] Update `YellowbookEKSNodeRole` with your actual node role name
- [ ] Optionally add your IAM user ARN

### Image References
- [ ] Update image names in deployment files to use your ECR registry
- [ ] Or use `kustomization.yaml` to transform image names automatically

## Resource Requirements

### API Application
- **Requests**: 200m CPU, 256Mi memory
- **Limits**: 500m CPU, 512Mi memory
- **Replicas**: 2-10 (auto-scaled)

### Web Application
- **Requests**: 200m CPU, 256Mi memory
- **Limits**: 500m CPU, 512Mi memory
- **Replicas**: 2-10 (auto-scaled)

### PostgreSQL
- **Requests**: 250m CPU, 256Mi memory
- **Limits**: 500m CPU, 512Mi memory
- **Storage**: 10Gi PVC

### Total Minimum Resources
- **CPU**: ~650m (API + Web + PostgreSQL requests)
- **Memory**: ~768Mi
- **Storage**: 10Gi

Recommended node type: **t3.medium** or larger (2 vCPU, 4 GiB memory)

## Health Checks

All application deployments include health checks:

### Liveness Probe
- Checks if container is running
- HTTP GET to health endpoint
- Failure threshold: 3
- Restarts pod on failure

### Readiness Probe
- Checks if container can accept traffic
- HTTP GET to health endpoint
- Failure threshold: 2
- Removes pod from service on failure

## Networking

### Services
- All services use `ClusterIP` type (internal only)
- External access via Ingress (ALB)

### Ingress
- Creates AWS Application Load Balancer
- Routes:
  - `yellowbook.example.com` → web-service:80
  - `api.yellowbook.example.com` → api-service:80
- TLS termination at ALB
- HTTP redirects to HTTPS

### DNS
- External DNS automatically creates Route53 records
- Points domain names to ALB hostname

## Auto-Scaling

HPA monitors CPU and memory usage:

### Scale-Up Behavior
- Trigger: CPU > 70% OR Memory > 80%
- Rate: 100% increase or +2 pods (max) every 30s
- Max replicas: 10

### Scale-Down Behavior
- Trigger: CPU < 70% AND Memory < 80%
- Rate: 50% decrease every 60s
- Stabilization: 5-minute window
- Min replicas: 2

## Troubleshooting

### View Resource Status
```bash
kubectl get all -n yellowbooks
kubectl get pvc -n yellowbooks
kubectl get ingress -n yellowbooks
```

### Check Logs
```bash
kubectl logs -f deployment/yellowbook-api -n yellowbooks
kubectl logs -f deployment/yellowbook-web -n yellowbooks
kubectl logs deployment/postgres -n yellowbooks
kubectl logs job/yellowbook-migration -n yellowbooks
```

### Describe Resources
```bash
kubectl describe pod <pod-name> -n yellowbooks
kubectl describe deployment yellowbook-api -n yellowbooks
kubectl describe ingress yellowbook-ingress -n yellowbooks
```

### Check Events
```bash
kubectl get events -n yellowbooks --sort-by='.lastTimestamp'
```

### Debug Pod Issues
```bash
# Execute into pod
kubectl exec -it deployment/yellowbook-api -n yellowbooks -- sh

# Port forward for local testing
kubectl port-forward svc/yellowbook-api-service 3001:80 -n yellowbooks
kubectl port-forward svc/yellowbook-web-service 3000:80 -n yellowbooks
```

## Updates and Rollbacks

### Update Deployment
```bash
# Update image
kubectl set image deployment/yellowbook-api api=new-image:tag -n yellowbooks

# Check rollout status
kubectl rollout status deployment/yellowbook-api -n yellowbooks

# View rollout history
kubectl rollout history deployment/yellowbook-api -n yellowbooks
```

### Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/yellowbook-api -n yellowbooks

# Rollback to specific revision
kubectl rollout undo deployment/yellowbook-api --to-revision=2 -n yellowbooks
```

## Security Best Practices

1. **Secrets Management**
   - Never commit actual credentials to git
   - Use AWS Secrets Manager or Parameter Store for production
   - Rotate credentials regularly

2. **RBAC**
   - Principle of least privilege
   - Separate service accounts for different components
   - Regular audit of permissions

3. **Network Policies**
   - Consider adding NetworkPolicy resources
   - Restrict pod-to-pod communication
   - Allow only necessary ingress/egress

4. **Image Security**
   - Use specific image tags, not `latest`
   - Scan images for vulnerabilities
   - Use minimal base images (alpine)

## Monitoring

### Metrics Server
Required for HPA, provides:
- Node CPU/memory usage
- Pod CPU/memory usage

```bash
kubectl top nodes
kubectl top pods -n yellowbooks
```

### CloudWatch Integration
Consider adding:
- Container Insights for EKS
- CloudWatch Logs for application logs
- CloudWatch Alarms for critical metrics

## Cost Optimization

1. **Right-size resources**
   - Monitor actual usage
   - Adjust requests/limits accordingly

2. **Use HPA effectively**
   - Scale down during off-peak hours
   - Set appropriate min/max replicas

3. **Storage**
   - Use appropriate storage class
   - Consider lifecycle policies

4. **Load Balancer**
   - Share ALB across multiple services
   - Use path-based routing

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Kustomize Documentation](https://kustomize.io/)

---

For full deployment instructions, see [../DEPLOY.md](../DEPLOY.md)
