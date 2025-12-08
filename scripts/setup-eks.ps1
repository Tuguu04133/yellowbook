# EKS Cluster Setup Script for Yellowbook (PowerShell)
# This script automates the initial setup of the EKS cluster and required AWS resources

$ErrorActionPreference = "Stop"

Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "Yellowbook EKS Cluster Setup" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

# Check required tools
Write-Host "Checking required tools..." -ForegroundColor Yellow
$requiredTools = @("aws", "eksctl", "kubectl", "helm")
foreach ($tool in $requiredTools) {
    if (!(Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "Error: $tool is required but not installed." -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ All required tools are installed" -ForegroundColor Green
Write-Host ""

# Configuration
$CLUSTER_NAME = if ($env:CLUSTER_NAME) { $env:CLUSTER_NAME } else { "yellowbook-cluster" }
$AWS_REGION = if ($env:AWS_REGION) { $env:AWS_REGION } else { "us-east-1" }
$NODE_TYPE = if ($env:NODE_TYPE) { $env:NODE_TYPE } else { "t3.medium" }
$DESIRED_NODES = if ($env:DESIRED_NODES) { $env:DESIRED_NODES } else { "3" }
$MIN_NODES = if ($env:MIN_NODES) { $env:MIN_NODES } else { "2" }
$MAX_NODES = if ($env:MAX_NODES) { $env:MAX_NODES } else { "5" }

Write-Host "Cluster Configuration:" -ForegroundColor Cyan
Write-Host "  Name: $CLUSTER_NAME"
Write-Host "  Region: $AWS_REGION"
Write-Host "  Node Type: $NODE_TYPE"
Write-Host "  Nodes: $MIN_NODES - $DESIRED_NODES - $MAX_NODES"
Write-Host ""

$confirmation = Read-Host "Do you want to continue with this configuration? (y/n)"
if ($confirmation -ne 'y') {
    Write-Host "Setup cancelled." -ForegroundColor Yellow
    exit 1
}

# Get AWS Account ID
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
Write-Host "AWS Account ID: $AWS_ACCOUNT_ID" -ForegroundColor Cyan
Write-Host ""

# 1. Create EKS Cluster
Write-Host "Step 1: Creating EKS Cluster..." -ForegroundColor Yellow
eksctl create cluster `
  --name $CLUSTER_NAME `
  --region $AWS_REGION `
  --nodegroup-name "$CLUSTER_NAME-nodes" `
  --node-type $NODE_TYPE `
  --nodes $DESIRED_NODES `
  --nodes-min $MIN_NODES `
  --nodes-max $MAX_NODES `
  --managed `
  --with-oidc

Write-Host "✓ EKS Cluster created" -ForegroundColor Green
Write-Host ""

# 2. Update kubeconfig
Write-Host "Step 2: Updating kubeconfig..." -ForegroundColor Yellow
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
Write-Host "✓ Kubeconfig updated" -ForegroundColor Green
Write-Host ""

# 3. Create ECR Repositories
Write-Host "Step 3: Creating ECR Repositories..." -ForegroundColor Yellow
try {
    aws ecr describe-repositories --repository-names yellowbook-api --region $AWS_REGION 2>$null
} catch {
    aws ecr create-repository --repository-name yellowbook-api --region $AWS_REGION
}
try {
    aws ecr describe-repositories --repository-names yellowbook-web --region $AWS_REGION 2>$null
} catch {
    aws ecr create-repository --repository-name yellowbook-web --region $AWS_REGION
}
Write-Host "✓ ECR Repositories created" -ForegroundColor Green
Write-Host ""

# 4. Get OIDC Provider
Write-Host "Step 4: Getting OIDC Provider..." -ForegroundColor Yellow
$OIDC_PROVIDER = (aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query "cluster.identity.oidc.issuer" --output text) -replace '^https://', ''
Write-Host "OIDC Provider: $OIDC_PROVIDER" -ForegroundColor Cyan
Write-Host ""

# 5. Create GitHub Actions IAM Role
Write-Host "Step 5: Setting up GitHub Actions OIDC Role..." -ForegroundColor Yellow
$GITHUB_USERNAME = Read-Host "Enter your GitHub username"
$GITHUB_REPO = Read-Host "Enter your repository name (default: yellowbook)"
if ([string]::IsNullOrEmpty($GITHUB_REPO)) { $GITHUB_REPO = "yellowbook" }

$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
"@

$trustPolicy | Out-File -FilePath "$env:TEMP\github-trust-policy.json" -Encoding utf8

try {
    aws iam create-role --role-name GitHubActionsDeployRole --assume-role-policy-document "file://$env:TEMP\github-trust-policy.json"
} catch {
    Write-Host "Role already exists, updating trust policy..." -ForegroundColor Yellow
    aws iam update-assume-role-policy --role-name GitHubActionsDeployRole --policy-document "file://$env:TEMP\github-trust-policy.json"
}

$deployPolicy = @"
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
"@

$deployPolicy | Out-File -FilePath "$env:TEMP\github-deploy-policy.json" -Encoding utf8

aws iam put-role-policy --role-name GitHubActionsDeployRole --policy-name GitHubActionsDeployPolicy --policy-document "file://$env:TEMP\github-deploy-policy.json"

Write-Host "✓ GitHub Actions IAM Role created" -ForegroundColor Green
Write-Host ""

# 6. Install AWS Load Balancer Controller
Write-Host "Step 6: Installing AWS Load Balancer Controller..." -ForegroundColor Yellow

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json" -OutFile "$env:TEMP\iam_policy.json"

try {
    aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document "file://$env:TEMP\iam_policy.json"
} catch {
    Write-Host "Policy already exists, continuing..." -ForegroundColor Yellow
}

eksctl create iamserviceaccount `
  --cluster=$CLUSTER_NAME `
  --namespace=kube-system `
  --name=aws-load-balancer-controller `
  --attach-policy-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" `
  --approve `
  --region=$AWS_REGION `
  --override-existing-serviceaccounts

helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller `
  -n kube-system `
  --set clusterName=$CLUSTER_NAME `
  --set serviceAccount.create=false `
  --set serviceAccount.name=aws-load-balancer-controller

Write-Host "✓ AWS Load Balancer Controller installed" -ForegroundColor Green
Write-Host ""

# 7. Install External DNS
Write-Host "Step 7: Installing External DNS for Route53..." -ForegroundColor Yellow

$externalDnsPolicy = @"
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
"@

$externalDnsPolicy | Out-File -FilePath "$env:TEMP\external-dns-policy.json" -Encoding utf8

try {
    aws iam create-policy --policy-name ExternalDNSPolicy --policy-document "file://$env:TEMP\external-dns-policy.json"
} catch {
    Write-Host "Policy already exists, continuing..." -ForegroundColor Yellow
}

eksctl create iamserviceaccount `
  --cluster=$CLUSTER_NAME `
  --namespace=kube-system `
  --name=external-dns `
  --attach-policy-arn="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/ExternalDNSPolicy" `
  --approve `
  --region=$AWS_REGION `
  --override-existing-serviceaccounts

$DOMAIN_NAME = Read-Host "Enter your domain name (e.g., example.com)"

$externalDnsManifest = @"
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
        - --domain-filter=${DOMAIN_NAME}
        - --provider=aws
        - --policy=upsert-only
        - --aws-zone-type=public
        - --registry=txt
        - --txt-owner-id=${CLUSTER_NAME}
"@

$externalDnsManifest | kubectl apply -f -

Write-Host "✓ External DNS installed" -ForegroundColor Green
Write-Host ""

# 8. Install Metrics Server
Write-Host "Step 8: Installing Metrics Server for HPA..." -ForegroundColor Yellow
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
Write-Host "✓ Metrics Server installed" -ForegroundColor Green
Write-Host ""

# 9. Output next steps
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Request ACM certificate for your domain:"
Write-Host "   aws acm request-certificate \"
Write-Host "     --domain-name $DOMAIN_NAME \"
Write-Host "     --subject-alternative-names api.$DOMAIN_NAME \"
Write-Host "     --validation-method DNS \"
Write-Host "     --region $AWS_REGION"
Write-Host ""
Write-Host "2. Add GitHub Secret:"
Write-Host "   Go to your GitHub repo → Settings → Secrets → Actions"
Write-Host "   Add secret: AWS_ACCOUNT_ID = $AWS_ACCOUNT_ID"
Write-Host ""
Write-Host "3. Update k8s/secret.yaml with your database credentials"
Write-Host ""
Write-Host "4. Update k8s/configmap.yaml with your domain:"
Write-Host "   NEXT_PUBLIC_API_URL: https://api.$DOMAIN_NAME"
Write-Host ""
Write-Host "5. Update k8s/ingress.yaml:"
Write-Host "   - Replace certificate ARN"
Write-Host "   - Replace domain names"
Write-Host ""
Write-Host "6. Update k8s/aws-auth.yaml with your AWS Account ID"
Write-Host ""
Write-Host "7. Commit and push to trigger deployment"
Write-Host ""
Write-Host "Cluster Info:" -ForegroundColor Cyan
Write-Host "  Name: $CLUSTER_NAME"
Write-Host "  Region: $AWS_REGION"
Write-Host "  Account ID: $AWS_ACCOUNT_ID"
Write-Host "  ECR Registry: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
