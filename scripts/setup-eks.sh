#!/bin/bash
# EKS Cluster Setup Script for Yellowbook
# This script automates the initial setup of the EKS cluster and required AWS resources

set -e

echo "==================================================================="
echo "Yellowbook EKS Cluster Setup"
echo "==================================================================="
echo ""

# Check required tools
echo "Checking required tools..."
command -v aws >/dev/null 2>&1 || { echo "aws-cli is required but not installed. Aborting." >&2; exit 1; }
command -v eksctl >/dev/null 2>&1 || { echo "eksctl is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Aborting." >&2; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed. Aborting." >&2; exit 1; }
echo "✓ All required tools are installed"
echo ""

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-yellowbook-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"
NODE_TYPE="${NODE_TYPE:-t3.medium}"
DESIRED_NODES="${DESIRED_NODES:-3}"
MIN_NODES="${MIN_NODES:-2}"
MAX_NODES="${MAX_NODES:-5}"

echo "Cluster Configuration:"
echo "  Name: $CLUSTER_NAME"
echo "  Region: $AWS_REGION"
echo "  Node Type: $NODE_TYPE"
echo "  Nodes: $MIN_NODES - $DESIRED_NODES - $MAX_NODES"
echo ""

read -p "Do you want to continue with this configuration? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Get AWS Account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# 1. Create EKS Cluster
echo "Step 1: Creating EKS Cluster..."
eksctl create cluster \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --nodegroup-name ${CLUSTER_NAME}-nodes \
  --node-type $NODE_TYPE \
  --nodes $DESIRED_NODES \
  --nodes-min $MIN_NODES \
  --nodes-max $MAX_NODES \
  --managed \
  --with-oidc

echo "✓ EKS Cluster created"
echo ""

# 2. Update kubeconfig
echo "Step 2: Updating kubeconfig..."
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
echo "✓ Kubeconfig updated"
echo ""

# 3. Create ECR Repositories
echo "Step 3: Creating ECR Repositories..."
aws ecr describe-repositories --repository-names yellowbook-api --region $AWS_REGION 2>/dev/null || \
  aws ecr create-repository --repository-name yellowbook-api --region $AWS_REGION
aws ecr describe-repositories --repository-names yellowbook-web --region $AWS_REGION 2>/dev/null || \
  aws ecr create-repository --repository-name yellowbook-web --region $AWS_REGION
echo "✓ ECR Repositories created"
echo ""

# 4. Get OIDC Provider
echo "Step 4: Getting OIDC Provider..."
export OIDC_PROVIDER=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --region $AWS_REGION \
  --query "cluster.identity.oidc.issuer" \
  --output text | sed -e 's|^https://||')
echo "OIDC Provider: $OIDC_PROVIDER"
echo ""

# 5. Create GitHub Actions IAM Role Trust Policy
echo "Step 5: Setting up GitHub Actions OIDC Role..."
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your repository name (default: yellowbook): " GITHUB_REPO
GITHUB_REPO="${GITHUB_REPO:-yellowbook}"

cat > /tmp/github-trust-policy.json <<EOF
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
EOF

# Create IAM Role
aws iam create-role \
  --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file:///tmp/github-trust-policy.json 2>/dev/null || \
  echo "Role already exists, updating trust policy..."
aws iam update-assume-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-document file:///tmp/github-trust-policy.json

# Create and attach deployment policy
cat > /tmp/github-deploy-policy.json <<EOF
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
EOF

aws iam put-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-name GitHubActionsDeployPolicy \
  --policy-document file:///tmp/github-deploy-policy.json

echo "✓ GitHub Actions IAM Role created"
echo ""

# 6. Install AWS Load Balancer Controller
echo "Step 6: Installing AWS Load Balancer Controller..."

# Download and create IAM policy
curl -o /tmp/iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json

aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file:///tmp/iam_policy.json 2>/dev/null || \
  echo "Policy already exists, continuing..."

# Create service account
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=$AWS_REGION \
  --override-existing-serviceaccounts

# Add helm repo and install
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

echo "✓ AWS Load Balancer Controller installed"
echo ""

# 7. Install External DNS
echo "Step 7: Installing External DNS for Route53..."

cat > /tmp/external-dns-policy.json <<EOF
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
  --policy-document file:///tmp/external-dns-policy.json 2>/dev/null || \
  echo "Policy already exists, continuing..."

eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=external-dns \
  --attach-policy-arn=arn:aws:iam::${AWS_ACCOUNT_ID}:policy/ExternalDNSPolicy \
  --approve \
  --region=$AWS_REGION \
  --override-existing-serviceaccounts

read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME

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
        - --domain-filter=${DOMAIN_NAME}
        - --provider=aws
        - --policy=upsert-only
        - --aws-zone-type=public
        - --registry=txt
        - --txt-owner-id=${CLUSTER_NAME}
EOF

echo "✓ External DNS installed"
echo ""

# 8. Install Metrics Server
echo "Step 8: Installing Metrics Server for HPA..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
echo "✓ Metrics Server installed"
echo ""

# 9. Output next steps
echo "==================================================================="
echo "Setup Complete!"
echo "==================================================================="
echo ""
echo "Next Steps:"
echo "1. Request ACM certificate for your domain:"
echo "   aws acm request-certificate \\"
echo "     --domain-name ${DOMAIN_NAME} \\"
echo "     --subject-alternative-names api.${DOMAIN_NAME} \\"
echo "     --validation-method DNS \\"
echo "     --region $AWS_REGION"
echo ""
echo "2. Add GitHub Secret:"
echo "   Go to your GitHub repo → Settings → Secrets → Actions"
echo "   Add secret: AWS_ACCOUNT_ID = $AWS_ACCOUNT_ID"
echo ""
echo "3. Update k8s/secret.yaml with your database credentials"
echo ""
echo "4. Update k8s/configmap.yaml with your domain:"
echo "   NEXT_PUBLIC_API_URL: https://api.${DOMAIN_NAME}"
echo ""
echo "5. Update k8s/ingress.yaml:"
echo "   - Replace certificate ARN"
echo "   - Replace domain names"
echo ""
echo "6. Update k8s/aws-auth.yaml with your AWS Account ID"
echo ""
echo "7. Commit and push to trigger deployment"
echo ""
echo "Cluster Info:"
echo "  Name: $CLUSTER_NAME"
echo "  Region: $AWS_REGION"
echo "  Account ID: $AWS_ACCOUNT_ID"
echo "  ECR Registry: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
echo ""
echo "==================================================================="
