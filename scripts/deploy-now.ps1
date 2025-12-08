# Yellowbook EKS Deployment Script
# Quick deployment automation for AWS EKS

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Yellowbook AWS EKS Deployment" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Get AWS Account ID
Write-Host "1. Getting AWS Account ID..." -ForegroundColor Yellow
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
if (-not $AWS_ACCOUNT_ID) {
    Write-Host "ERROR: AWS CLI not configured!" -ForegroundColor Red
    Write-Host "Run 'aws configure' to set up AWS credentials" -ForegroundColor Yellow
    exit 1
}
Write-Host "Success - AWS Account ID: $AWS_ACCOUNT_ID" -ForegroundColor Green
Write-Host ""

# 2. Get domain name
Write-Host "2. Enter domain name..." -ForegroundColor Yellow
$DOMAIN = Read-Host "Your domain (example: example.com)"
if ([string]::IsNullOrEmpty($DOMAIN)) {
    Write-Host "ERROR: Domain name required!" -ForegroundColor Red
    exit 1
}
Write-Host "Success - Domain: $DOMAIN" -ForegroundColor Green
Write-Host ""

# 3. Get GitHub username
Write-Host "3. GitHub information..." -ForegroundColor Yellow
$GITHUB_USER = Read-Host "GitHub username"
if ([string]::IsNullOrEmpty($GITHUB_USER)) {
    $GITHUB_USER = "Tuguu04133"
}
Write-Host "Success - GitHub User: $GITHUB_USER" -ForegroundColor Green
Write-Host ""

# 4. Check EKS cluster
Write-Host "4. Checking EKS cluster..." -ForegroundColor Yellow
$clusterExists = aws eks describe-cluster --name yellowbook-cluster --region us-east-1 2>$null
if (-not $clusterExists) {
    Write-Host "Warning - EKS cluster not found. Create it? (y/n)" -ForegroundColor Yellow
    $createCluster = Read-Host
    if ($createCluster -eq 'y') {
        Write-Host "Running setup script..." -ForegroundColor Cyan
        & ".\scripts\setup-eks.ps1"
    } else {
        Write-Host "Please run setup script: .\scripts\setup-eks.ps1" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "Success - EKS cluster found" -ForegroundColor Green
}
Write-Host ""

# 5. Update kubeconfig
Write-Host "5. Updating kubeconfig..." -ForegroundColor Yellow
aws eks update-kubeconfig --region us-east-1 --name yellowbook-cluster
Write-Host "Success - kubeconfig updated" -ForegroundColor Green
Write-Host ""

# 6. Check ACM Certificate
Write-Host "6. Checking ACM Certificate..." -ForegroundColor Yellow
$certs = aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='yellowbook.$DOMAIN'].CertificateArn" --output text
if ([string]::IsNullOrEmpty($certs)) {
    Write-Host "Warning - Certificate not found. Create it? (y/n)" -ForegroundColor Yellow
    $createCert = Read-Host
    if ($createCert -eq 'y') {
        aws acm request-certificate `
            --domain-name "yellowbook.$DOMAIN" `
            --subject-alternative-names "api.yellowbook.$DOMAIN" `
            --validation-method DNS `
            --region us-east-1
        Write-Host "Warning - Certificate created! Go to AWS Console to complete DNS validation!" -ForegroundColor Yellow
        Write-Host "URL: https://console.aws.amazon.com/acm/home?region=us-east-1" -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Press Enter after completing DNS validation"
        
        # Get certificate ARN again
        $certs = aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[?DomainName=='yellowbook.$DOMAIN'].CertificateArn" --output text
    }
}

if (-not [string]::IsNullOrEmpty($certs)) {
    Write-Host "Success - Certificate ARN: $certs" -ForegroundColor Green
} else {
    Write-Host "ERROR: Certificate not created!" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 7. Update configuration files
Write-Host "7. Updating configuration files..." -ForegroundColor Yellow

# Generate secrets
$DB_PASSWORD = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object {[char]$_})
$JWT_SECRET = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})

# Update secret.yaml
$secretContent = @"
apiVersion: v1
kind: Secret
metadata:
  name: yellowbook-secrets
  namespace: yellowbooks
type: Opaque
stringData:
  DATABASE_URL: "postgresql://yellowbook:$DB_PASSWORD@postgres-service:5432/yellowbook?schema=public"
  JWT_SECRET: "$JWT_SECRET"
"@
[System.IO.File]::WriteAllText("$PWD\k8s\secret.yaml", $secretContent)
Write-Host "Success - secret.yaml updated" -ForegroundColor Green

# Update configmap.yaml
$configContent = @"
apiVersion: v1
kind: ConfigMap
metadata:
  name: yellowbook-config
  namespace: yellowbooks
data:
  NODE_ENV: "production"
  PORT: "3000"
  API_PORT: "3001"
  NEXT_PUBLIC_API_URL: "https://api.yellowbook.$DOMAIN"
"@
[System.IO.File]::WriteAllText("$PWD\k8s\configmap.yaml", $configContent)
Write-Host "Success - configmap.yaml updated" -ForegroundColor Green

# Update ingress.yaml
$ingressContent = Get-Content k8s\ingress.yaml -Raw
$ingressContent = $ingressContent -replace 'arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERTIFICATE_ID', $certs
$ingressContent = $ingressContent -replace 'yellowbook\.example\.com', "yellowbook.$DOMAIN"
$ingressContent = $ingressContent -replace 'api\.yellowbook\.example\.com', "api.yellowbook.$DOMAIN"
[System.IO.File]::WriteAllText("$PWD\k8s\ingress.yaml", $ingressContent)
Write-Host "Success - ingress.yaml updated" -ForegroundColor Green

# Update aws-auth.yaml
$awsAuthContent = Get-Content k8s\aws-auth.yaml -Raw
$awsAuthContent = $awsAuthContent -replace 'ACCOUNT_ID', $AWS_ACCOUNT_ID
[System.IO.File]::WriteAllText("$PWD\k8s\aws-auth.yaml", $awsAuthContent)
Write-Host "Success - aws-auth.yaml updated" -ForegroundColor Green

Write-Host ""

# 8. Ask about deployment
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Proceed with deployment? (y/n)" -ForegroundColor Yellow
$deploy = Read-Host

if ($deploy -ne 'y') {
    Write-Host ""
    Write-Host "To deploy manually, run these commands:" -ForegroundColor Cyan
    Write-Host "  1. Add GitHub Secret: AWS_ACCOUNT_ID = $AWS_ACCOUNT_ID" -ForegroundColor Yellow
    Write-Host "  2. git add . ; git commit -m 'Deploy config' ; git push" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or run manually:" -ForegroundColor Cyan
    Write-Host "  .\scripts\deploy-manual.ps1" -ForegroundColor Yellow
    exit 0
}

# 9. Docker images build and push
Write-Host ""
Write-Host "8. Building and pushing Docker images..." -ForegroundColor Yellow

# ECR login
Write-Host "Logging into ECR..." -ForegroundColor Cyan
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com"

# API image
Write-Host "Building API image..." -ForegroundColor Cyan
docker build -t "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest" -f Dockerfile.api .
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest"
Write-Host "Success - API image pushed" -ForegroundColor Green

# Web image
Write-Host "Building Web image..." -ForegroundColor Cyan
docker build -t "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest" -f Dockerfile.web .
docker push "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest"
Write-Host "Success - Web image pushed" -ForegroundColor Green
Write-Host ""

# 10. Kubernetes deploy
Write-Host "9. Starting Kubernetes deployment..." -ForegroundColor Yellow

# Namespace
kubectl apply -f k8s\namespace.yaml
Write-Host "Success - Namespace created" -ForegroundColor Green

# ConfigMap and Secret
kubectl apply -f k8s\configmap.yaml
kubectl apply -f k8s\secret.yaml
Write-Host "Success - ConfigMap and Secret created" -ForegroundColor Green

# Update PostgreSQL secret
$pgSecretContent = Get-Content k8s\postgres-deployment.yaml -Raw
$pgSecretContent = $pgSecretContent -replace 'changeme123', $DB_PASSWORD
[System.IO.File]::WriteAllText("$PWD\k8s\postgres-deployment.yaml", $pgSecretContent)

# PostgreSQL
kubectl apply -f k8s\postgres-deployment.yaml
Write-Host "Waiting for PostgreSQL to be ready..." -ForegroundColor Cyan
kubectl wait --for=condition=ready pod -l app=postgres -n yellowbooks --timeout=300s
Write-Host "Success - PostgreSQL ready" -ForegroundColor Green

# Update migration job
$migrationContent = Get-Content k8s\migration-job.yaml -Raw
$migrationContent = $migrationContent -replace 'tuguu04133/yellowbook-api:latest', "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest"
[System.IO.File]::WriteAllText("$PWD\k8s\migration-job.yaml", $migrationContent)

# Migration
kubectl delete job yellowbook-migration -n yellowbooks --ignore-not-found=true
kubectl apply -f k8s\migration-job.yaml
Write-Host "Running migration..." -ForegroundColor Cyan
kubectl wait --for=condition=complete job/yellowbook-migration -n yellowbooks --timeout=300s
Write-Host "Success - Migration complete" -ForegroundColor Green

# Update API deployment
$apiContent = Get-Content k8s\api-deployment.yaml -Raw
$apiContent = $apiContent -replace 'tuguu04133/yellowbook-api:latest', "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest"
[System.IO.File]::WriteAllText("$PWD\k8s\api-deployment.yaml", $apiContent)

# Update Web deployment
$webContent = Get-Content k8s\web-deployment.yaml -Raw
$webContent = $webContent -replace 'tuguu04133/yellowbook-web:latest', "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest"
[System.IO.File]::WriteAllText("$PWD\k8s\web-deployment.yaml", $webContent)

# Apps deploy
kubectl apply -f k8s\api-deployment.yaml
kubectl apply -f k8s\web-deployment.yaml
Write-Host "Success - API and Web deployments created" -ForegroundColor Green

# HPA and Ingress
kubectl apply -f k8s\hpa.yaml
kubectl apply -f k8s\ingress.yaml
Write-Host "Success - HPA and Ingress created" -ForegroundColor Green

# RBAC
kubectl apply -f k8s\rbac.yaml
Write-Host "Success - RBAC configured" -ForegroundColor Green

Write-Host ""
Write-Host "Waiting for deployments to be ready..." -ForegroundColor Cyan
kubectl rollout status deployment/yellowbook-api -n yellowbooks --timeout=300s
kubectl rollout status deployment/yellowbook-web -n yellowbooks --timeout=300s
Write-Host ""

# 11. Validation
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Deployment Successful!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pods:" -ForegroundColor Cyan
kubectl get pods -n yellowbooks
Write-Host ""

Write-Host "Services:" -ForegroundColor Cyan
kubectl get svc -n yellowbooks
Write-Host ""

Write-Host "Ingress:" -ForegroundColor Cyan
kubectl get ingress -n yellowbooks
Write-Host ""

$LB_URL = kubectl get ingress yellowbook-ingress -n yellowbooks -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
if ($LB_URL) {
    Write-Host "Load Balancer URL: $LB_URL" -ForegroundColor Green
}
Write-Host ""

Write-Host "HPA:" -ForegroundColor Cyan
kubectl get hpa -n yellowbooks
Write-Host ""

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Wait for DNS propagation (5-10 minutes)" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Access your website:" -ForegroundColor Yellow
Write-Host "   https://yellowbook.$DOMAIN" -ForegroundColor Cyan
Write-Host "   https://api.yellowbook.$DOMAIN" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Validation commands:" -ForegroundColor Yellow
Write-Host "   kubectl get pods -n yellowbooks" -ForegroundColor Cyan
Write-Host "   kubectl logs -f deployment/yellowbook-api -n yellowbooks" -ForegroundColor Cyan
Write-Host "   .\scripts\validate-deployment.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "4. Take screenshots:" -ForegroundColor Yellow
Write-Host "   - Browser + HTTPS padlock" -ForegroundColor Cyan
Write-Host "   - kubectl get pods" -ForegroundColor Cyan
Write-Host "   - GitHub Actions (if used)" -ForegroundColor Cyan
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Good luck!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
