# Yellowbook EKS Deployment Guide

This guide provides comprehensive instructions for deploying the Yellowbook application to AWS EKS with OIDC authentication, TLS/HTTPS, database migrations, and auto-scaling.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [AWS Setup](#aws-setup)
3. [OIDC Configuration](#oidc-configuration)
4. [EKS Cluster Setup](#eks-cluster-setup)
5. [AWS Auth & RBAC](#aws-auth--rbac)
6. [Kubernetes Manifests](#kubernetes-manifests)
7. [Ingress & TLS Setup](#ingress--tls-setup)
8. [Database Migration](#database-migration)
9. [Horizontal Pod Autoscaler](#horizontal-pod-autoscaler)
10. [Deployment](#deployment)
11. [Verification](#verification)
12. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- kubectl installed
- Docker installed
- eksctl installed
- Domain name managed by Route53 (or ability to configure DNS)
- GitHub repository with appropriate access

## AWS Setup

### 1. Create EKS Cluster

```bash
eksctl create cluster \
  --name yellowbook-cluster \
  --region us-east-1 \
  --nodegroup-name yellowbook-nodes \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 5 \
  --managed \
  --with-oidc
```

### 2. Create ECR Repositories

```bash
aws ecr create-repository --repository-name yellowbook-api --region us-east-1
aws ecr create-repository --repository-name yellowbook-web --region us-east-1
```

### 3. Get AWS Account ID

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo $AWS_ACCOUNT_ID
```

---

## OIDC Configuration

### 1. Enable OIDC Provider for EKS

```bash
eksctl utils associate-iam-oidc-provider \
  --cluster yellowbook-cluster \
  --region us-east-1 \
  --approve
```

### 2. Get OIDC Provider URL

```bash
export OIDC_PROVIDER=$(aws eks describe-cluster \
  --name yellowbook-cluster \
  --region us-east-1 \
  --query "cluster.identity.oidc.issuer" \
  --output text | sed -e 's|^https://||')

echo $OIDC_PROVIDER
```

### 3. Create IAM Role for GitHub Actions

Create a trust policy file `github-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/yellowbook:*"
        }
      }
    }
  ]
}
```

**Replace:**
- `ACCOUNT_ID` with your AWS Account ID
- `YOUR_GITHUB_USERNAME` with your GitHub username

### 4. Create the IAM Role

```bash
aws iam create-role \
  --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file://github-trust-policy.json
```

### 5. Create IAM Policy for Deployment

Create `github-deploy-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity"
      ],
      "Resource": "*"
    }
  ]
}
```

### 6. Attach Policy to Role

```bash
aws iam put-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-name GitHubActionsDeployPolicy \
  --policy-document file://github-deploy-policy.json
```

---

## AWS Auth & RBAC

### 1. Configure aws-auth ConfigMap

First, get your node instance role:

```bash
kubectl describe configmap -n kube-system aws-auth
```

Edit `k8s/aws-auth.yaml` and replace:
- `ACCOUNT_ID` with your AWS Account ID
- `YellowbookEKSNodeRole` with your actual node instance role name
- `YOUR_IAM_USER` with your IAM username (optional)

Apply the ConfigMap:

```bash
kubectl apply -f k8s/aws-auth.yaml
```

### 2. Apply RBAC Resources

```bash
kubectl apply -f k8s/rbac.yaml
```

This creates:
- ServiceAccount: `yellowbook-deployer`
- Role: `yellowbook-deployer-role` (namespace-scoped permissions)
- RoleBinding: `yellowbook-deployer-binding`
- ClusterRole: `yellowbook-viewer` (cluster-wide read permissions)
- ClusterRoleBinding: `yellowbook-viewer-binding`

---

## Kubernetes Manifests

### Overview of Manifests

The deployment consists of the following Kubernetes resources:

#### 1. Namespace (`namespace.yaml`)
- Creates `yellowbooks` namespace for all resources

#### 2. ConfigMap & Secrets (`configmap.yaml`, `secret.yaml`)
- **ConfigMap**: Non-sensitive configuration (ports, URLs)
- **Secret**: Sensitive data (database credentials, JWT secrets)

**Important**: Update `secret.yaml` with your actual credentials before deploying!

#### 3. PostgreSQL Database (`postgres-deployment.yaml`)
- **PersistentVolumeClaim**: 10Gi storage for database
- **Deployment**: PostgreSQL 15 container
- **Service**: ClusterIP service for internal access
- Uses ConfigMap and Secret for configuration

#### 4. API Application (`api-deployment.yaml`)
- **Deployment**: 2 replicas of the API server
- **Service**: ClusterIP service exposing port 80
- Includes health checks (liveness/readiness probes)
- Resource requests and limits configured

#### 5. Web Application (`web-deployment.yaml`)
- **Deployment**: 2 replicas of the Next.js frontend
- **Service**: ClusterIP service exposing port 80
- Includes health checks
- Resource requests and limits configured

#### 6. Database Migration Job (`migration-job.yaml`)
- **Job**: Runs Prisma migrations on deployment
- Includes init container to wait for PostgreSQL
- Runs `npx prisma migrate deploy`
- TTL set to auto-cleanup after completion

#### 7. Horizontal Pod Autoscaler (`hpa.yaml`)
- **HPA for API**: Scales 2-10 replicas based on CPU (70%) and memory (80%)
- **HPA for Web**: Scales 2-10 replicas based on CPU (70%) and memory (80%)
- Intelligent scale-up/scale-down policies

#### 8. Ingress (`ingress.yaml`)
- **AWS ALB Ingress Controller** configuration
- Routes traffic to web and API services
- SSL/TLS termination with ACM certificate
- HTTP to HTTPS redirect
- Route53 integration via External DNS

---

## Ingress & TLS Setup

### 1. Install AWS Load Balancer Controller

```bash
# Download IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json

# Create IAM policy
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=yellowbook-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=us-east-1

# Add eks-charts repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=yellowbook-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 2. Request ACM Certificate

```bash
aws acm request-certificate \
  --domain-name yellowbook.example.com \
  --subject-alternative-names api.yellowbook.example.com \
  --validation-method DNS \
  --region us-east-1
```

**Important**: Complete DNS validation in Route53!

### 3. Install External DNS (for Route53 automation)

```bash
# Create IAM policy for External DNS
cat > external-dns-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name ExternalDNSPolicy \
  --policy-document file://external-dns-policy.json

# Create service account
eksctl create iamserviceaccount \
  --cluster=yellowbook-cluster \
  --namespace=kube-system \
  --name=external-dns \
  --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/ExternalDNSPolicy \
  --approve \
  --region=us-east-1

# Deploy External DNS
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.14.0
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=example.com
        - --provider=aws
        - --policy=upsert-only
        - --aws-zone-type=public
        - --registry=txt
        - --txt-owner-id=yellowbook-cluster
EOF
```

### 4. Update Ingress Configuration

Edit `k8s/ingress.yaml`:
1. Replace `ACCOUNT_ID` and `CERTIFICATE_ID` in the certificate ARN annotation
2. Replace `example.com` with your actual domain name

Get your certificate ARN:
```bash
aws acm list-certificates --region us-east-1
```

---

## Database Migration

### Migration Job Details

The migration job (`migration-job.yaml`) performs the following:

1. **Wait for PostgreSQL**: Init container checks PostgreSQL availability
2. **Run Migrations**: Executes `npx prisma migrate deploy`
3. **Auto-cleanup**: Job is deleted after 5 minutes (TTL)

### Manual Migration Execution

If you need to run migrations manually:

```bash
# Delete existing job
kubectl delete job yellowbook-migration -n yellowbooks --ignore-not-found=true

# Apply migration job
kubectl apply -f k8s/migration-job.yaml

# Watch job progress
kubectl get jobs -n yellowbooks -w

# View migration logs
kubectl logs -n yellowbooks job/yellowbook-migration

# Check job status
kubectl describe job yellowbook-migration -n yellowbooks
```

### Database Seeding

To seed the database:

```bash
kubectl run seed-job --image=${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest \
  -n yellowbooks \
  --rm -it --restart=Never \
  --env="DATABASE_URL=$(kubectl get secret yellowbook-secrets -n yellowbooks -o jsonpath='{.data.DATABASE_URL}' | base64 -d)" \
  -- npx prisma db seed
```

---

## Horizontal Pod Autoscaler

### HPA Configuration

Both API and Web applications have HPA configured with:

- **Min Replicas**: 2
- **Max Replicas**: 10
- **CPU Target**: 70% utilization
- **Memory Target**: 80% utilization

### Scale-Up Policy
- Increase by 100% or 2 pods (whichever is greater) every 30 seconds

### Scale-Down Policy
- Decrease by 50% every 60 seconds
- 5-minute stabilization window to prevent flapping

### Monitor HPA

```bash
# View HPA status
kubectl get hpa -n yellowbooks

# Detailed HPA information
kubectl describe hpa yellowbook-api-hpa -n yellowbooks
kubectl describe hpa yellowbook-web-hpa -n yellowbooks

# Watch HPA in real-time
kubectl get hpa -n yellowbooks -w
```

### Test Auto-Scaling

Generate load to test HPA:

```bash
# Install hey (HTTP load generator)
# Then run load test
hey -z 5m -c 50 https://api.yellowbook.example.com/api/yellow-books
```

---

## Deployment

### GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add secret: `AWS_ACCOUNT_ID` = Your AWS Account ID

### Deployment Workflow

The GitHub Actions workflow (`.github/workflows/deploy-eks.yml`) performs:

1. **Checkout code**
2. **Configure AWS credentials** using OIDC (no access keys needed!)
3. **Login to ECR**
4. **Build and push** Docker images (API and Web)
5. **Update kubeconfig** for EKS cluster access
6. **Deploy namespace**
7. **Deploy ConfigMap and Secrets**
8. **Deploy PostgreSQL** and wait for readiness
9. **Run database migration job** and wait for completion
10. **Deploy API and Web applications** with new image tags
11. **Deploy HPA**
12. **Deploy Ingress**
13. **Verify deployment** and show pod status

### Manual Deployment

If you prefer to deploy manually:

```bash
# 1. Build and push images
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest -f Dockerfile.api .
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest -f Dockerfile.web .

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com

docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest

# 2. Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name yellowbook-cluster

# 3. Apply manifests in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/postgres-deployment.yaml

# Wait for PostgreSQL
kubectl wait --for=condition=ready pod -l app=postgres -n yellowbooks --timeout=300s

# Run migration
kubectl apply -f k8s/migration-job.yaml
kubectl wait --for=condition=complete job/yellowbook-migration -n yellowbooks --timeout=300s

# Deploy applications
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/web-deployment.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml

# Wait for deployments
kubectl rollout status deployment/yellowbook-api -n yellowbooks
kubectl rollout status deployment/yellowbook-web -n yellowbooks
```

---

## Verification

### 1. Check Pods

```bash
kubectl get pods -n yellowbooks
```

Expected output:
```
NAME                              READY   STATUS    RESTARTS   AGE
postgres-xxx                      1/1     Running   0          5m
yellowbook-api-xxx                1/1     Running   0          2m
yellowbook-api-yyy                1/1     Running   0          2m
yellowbook-web-xxx                1/1     Running   0          2m
yellowbook-web-yyy                1/1     Running   0          2m
```

### 2. Check Services

```bash
kubectl get svc -n yellowbooks
```

### 3. Check Ingress

```bash
kubectl get ingress -n yellowbooks
kubectl describe ingress yellowbook-ingress -n yellowbooks
```

Get the Load Balancer URL:
```bash
kubectl get ingress yellowbook-ingress -n yellowbooks -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 4. Check HPA

```bash
kubectl get hpa -n yellowbooks
```

### 5. View Logs

```bash
# API logs
kubectl logs -f deployment/yellowbook-api -n yellowbooks

# Web logs
kubectl logs -f deployment/yellowbook-web -n yellowbooks

# Migration logs
kubectl logs job/yellowbook-migration -n yellowbooks
```

### 6. Test Application

Once DNS is configured, access:
- **Web**: https://yellowbook.example.com
- **API**: https://api.yellowbook.example.com

Verify the padlock (🔒) is visible in the browser for HTTPS.

### 7. Take Screenshots

For submission:

1. **Public HTTPS URL + Padlock**
   - Open https://yellowbook.example.com in browser
   - Take screenshot showing URL bar with padlock

2. **GitHub Actions Run**
   - Go to Actions tab in GitHub
   - Click on latest workflow run
   - Take screenshot showing "build + deploy succeeded"

3. **Kubectl Pods**
   ```bash
   kubectl get pods -n yellowbooks
   ```
   Take screenshot showing all pods in Ready state

---

## Troubleshooting

### Pods Not Starting

```bash
# Check pod details
kubectl describe pod <pod-name> -n yellowbooks

# Check logs
kubectl logs <pod-name> -n yellowbooks

# Check events
kubectl get events -n yellowbooks --sort-by='.lastTimestamp'
```

### Database Connection Issues

```bash
# Check PostgreSQL logs
kubectl logs deployment/postgres -n yellowbooks

# Verify secret
kubectl get secret yellowbook-secrets -n yellowbooks -o yaml

# Test connection from API pod
kubectl exec -it deployment/yellowbook-api -n yellowbooks -- sh
# Inside pod:
# npx prisma db pull
```

### Migration Job Fails

```bash
# View migration logs
kubectl logs job/yellowbook-migration -n yellowbooks

# Delete and re-run
kubectl delete job yellowbook-migration -n yellowbooks
kubectl apply -f k8s/migration-job.yaml
```

### Ingress Not Working

```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify Ingress
kubectl describe ingress yellowbook-ingress -n yellowbooks

# Check ALB in AWS Console
# EC2 → Load Balancers
```

### HPA Not Scaling

```bash
# Check metrics server
kubectl top nodes
kubectl top pods -n yellowbooks

# If metrics not available, install metrics server:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### OIDC Authentication Issues

```bash
# Verify OIDC provider
aws eks describe-cluster --name yellowbook-cluster --query "cluster.identity.oidc.issuer"

# Check IAM role trust policy
aws iam get-role --role-name GitHubActionsDeployRole
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Internet                              │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTPS (443)
                         │
                    ┌────▼────┐
                    │ Route53 │
                    └────┬────┘
                         │
            ┌────────────┴────────────┐
            │                         │
      ┌─────▼─────┐            ┌─────▼─────┐
      │   ALB     │            │   ALB     │
      │ (Web)     │            │  (API)    │
      └─────┬─────┘            └─────┬─────┘
            │                         │
     ┌──────▼───────┐          ┌──────▼───────┐
     │   Ingress    │          │   Ingress    │
     │ Controller   │          │ Controller   │
     └──────┬───────┘          └──────┬───────┘
            │                         │
     ┌──────▼───────┐          ┌──────▼───────┐
     │ Web Service  │          │ API Service  │
     │ (ClusterIP)  │          │ (ClusterIP)  │
     └──────┬───────┘          └──────┬───────┘
            │                         │
     ┌──────▼────────┐         ┌──────▼────────┐
     │  Web Pods     │         │  API Pods     │
     │  (2-10)       │         │  (2-10)       │
     │  + HPA        │         │  + HPA        │
     └───────────────┘         └───────┬───────┘
                                       │
                                       │
                              ┌────────▼────────┐
                              │   PostgreSQL    │
                              │   (ClusterIP)   │
                              └─────────────────┘
```

---

## Cleanup

To delete all resources:

```bash
# Delete Kubernetes resources
kubectl delete namespace yellowbooks

# Delete AWS Load Balancer Controller
helm uninstall aws-load-balancer-controller -n kube-system

# Delete External DNS
kubectl delete deployment external-dns -n kube-system

# Delete EKS cluster
eksctl delete cluster --name yellowbook-cluster --region us-east-1

# Delete ECR repositories
aws ecr delete-repository --repository-name yellowbook-api --force --region us-east-1
aws ecr delete-repository --repository-name yellowbook-web --force --region us-east-1

# Delete IAM roles and policies
aws iam delete-role-policy --role-name GitHubActionsDeployRole --policy-name GitHubActionsDeployPolicy
aws iam delete-role --role-name GitHubActionsDeployRole
```

---

## Checklist for Submission

- [ ] OIDC/Roles configured (20 pts)
  - [ ] IAM OIDC provider enabled for EKS
  - [ ] GitHub Actions role created with trust policy
  - [ ] Deployment policy attached to role

- [ ] aws-auth/RBAC (10 pts)
  - [ ] aws-auth ConfigMap updated
  - [ ] ServiceAccount created
  - [ ] Role and RoleBinding applied

- [ ] Manifests (25 pts)
  - [ ] Namespace created
  - [ ] ConfigMap and Secret configured
  - [ ] PostgreSQL deployment with PVC
  - [ ] API and Web deployments
  - [ ] Services created

- [ ] Ingress/TLS (20 pts)
  - [ ] AWS Load Balancer Controller installed
  - [ ] ACM certificate created and validated
  - [ ] Ingress configured with TLS
  - [ ] External DNS configured for Route53
  - [ ] HTTPS working with padlock visible

- [ ] Migration Job (10 pts)
  - [ ] Migration job manifest created
  - [ ] Job runs successfully before app deployment
  - [ ] Database schema up to date

- [ ] HPA (10 pts)
  - [ ] HPA configured for API
  - [ ] HPA configured for Web
  - [ ] Metrics server installed
  - [ ] Scaling policies defined

- [ ] Docs (5 pts)
  - [ ] DEPLOY.md created with all steps
  - [ ] OIDC setup documented
  - [ ] Manifest explanations included
  - [ ] Ingress/TLS configuration documented

- [ ] Screenshots
  - [ ] Public HTTPS URL with padlock visible
  - [ ] GitHub Actions run link (build + deploy succeeded)
  - [ ] `kubectl get pods -n yellowbooks` showing Ready pods

---

## Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [External DNS](https://github.com/kubernetes-sigs/external-dns)
- [Prisma Documentation](https://www.prisma.io/docs/)

---

**Good luck with your deployment! 🚀**
