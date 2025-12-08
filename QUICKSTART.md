# Quick Start Guide for Yellowbook EKS Deployment

This is a quick reference guide for deploying Yellowbook to AWS EKS. For comprehensive documentation, see [DEPLOY.md](DEPLOY.md).

## Prerequisites

- AWS CLI configured
- eksctl installed
- kubectl installed
- helm installed
- Docker installed
- Domain in Route53

## Quick Setup (5 Steps)

### 1. Run Setup Script

**Linux/Mac:**
```bash
chmod +x scripts/setup-eks.sh
./scripts/setup-eks.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\setup-eks.ps1
```

This script will:
- Create EKS cluster
- Create ECR repositories
- Set up OIDC for GitHub Actions
- Install AWS Load Balancer Controller
- Install External DNS
- Install Metrics Server

### 2. Request ACM Certificate

```bash
aws acm request-certificate \
  --domain-name your-domain.com \
  --subject-alternative-names api.your-domain.com \
  --validation-method DNS \
  --region us-east-1
```

Validate via Route53 DNS records.

### 3. Update Configuration Files

```bash
# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get ACM Certificate ARN
aws acm list-certificates --region us-east-1
```

Update these files:
- `k8s/secret.yaml` - Database credentials
- `k8s/configmap.yaml` - Domain URLs
- `k8s/ingress.yaml` - Certificate ARN and domain names
- `k8s/aws-auth.yaml` - AWS Account ID

### 4. Add GitHub Secret

1. Go to: `Settings → Secrets and variables → Actions`
2. Click "New repository secret"
3. Name: `AWS_ACCOUNT_ID`
4. Value: Your AWS Account ID

### 5. Deploy

```bash
git add .
git commit -m "Add EKS deployment configuration"
git push origin main
```

GitHub Actions will automatically:
- Build Docker images
- Push to ECR
- Run database migrations
- Deploy to EKS

## Verify Deployment

```bash
# Check pods
kubectl get pods -n yellowbooks

# Check services
kubectl get svc -n yellowbooks

# Check ingress
kubectl get ingress -n yellowbooks

# Get Load Balancer URL
kubectl get ingress yellowbook-ingress -n yellowbooks -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Access Your Application

- **Web**: https://your-domain.com
- **API**: https://api.your-domain.com

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <pod-name> -n yellowbooks
kubectl logs <pod-name> -n yellowbooks
```

### Migration fails
```bash
kubectl logs job/yellowbook-migration -n yellowbooks
kubectl delete job yellowbook-migration -n yellowbooks
kubectl apply -f k8s/migration-job.yaml
```

### Ingress issues
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe ingress yellowbook-ingress -n yellowbooks
```

## Manual Deployment

If you prefer manual deployment:

```bash
# Build and push images
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest -f Dockerfile.api .
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest -f Dockerfile.web .

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest

# Deploy to Kubernetes
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/postgres-deployment.yaml

# Wait for PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n yellowbooks --timeout=300s

# Run migration
kubectl apply -f k8s/migration-job.yaml
kubectl wait --for=condition=complete job/yellowbook-migration -n yellowbooks --timeout=300s

# Deploy apps
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/web-deployment.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml
```

## Cleanup

```bash
# Delete all resources
kubectl delete namespace yellowbooks

# Delete cluster
eksctl delete cluster --name yellowbook-cluster --region us-east-1

# Delete ECR repositories
aws ecr delete-repository --repository-name yellowbook-api --force --region us-east-1
aws ecr delete-repository --repository-name yellowbook-web --force --region us-east-1
```

## Common Commands

```bash
# View logs
kubectl logs -f deployment/yellowbook-api -n yellowbooks
kubectl logs -f deployment/yellowbook-web -n yellowbooks

# Scale manually
kubectl scale deployment yellowbook-api --replicas=5 -n yellowbooks

# Update image
kubectl set image deployment/yellowbook-api api=${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:v2 -n yellowbooks

# Restart deployment
kubectl rollout restart deployment/yellowbook-api -n yellowbooks

# Check HPA status
kubectl get hpa -n yellowbooks -w
```

## Resources

- [Full Documentation](DEPLOY.md)
- [AWS EKS Docs](https://docs.aws.amazon.com/eks/)
- [Kubernetes Docs](https://kubernetes.io/docs/)

---

**Need help?** Check the full [DEPLOY.md](DEPLOY.md) for detailed troubleshooting.
