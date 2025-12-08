# Yellowbook Deployment - Хурдан Заавар

Энэ файл нь deployment хийх шууд командуудыг агуулна.

## 1. Эхлэх өмнө

### AWS CLI тохируулах
```powershell
# AWS эрхээ тохируулах
aws configure
# AWS Access Key ID: таны access key
# AWS Secret Access Key: таны secret key
# Default region: us-east-1
# Default output format: json
```

### GitHub Repository Clone
```powershell
git clone https://github.com/Tuguu04133/yellowbook.git
cd yellowbook
```

## 2. EKS Кластер Үүсгэх (15-20 минут)

```powershell
# Setup script ажиллуулах
.\scripts\setup-eks.ps1
```

**Энэ нь:**
- EKS кластер үүсгэнэ
- ECR repositories үүсгэнэ
- OIDC тохируулна
- Load Balancer Controller суулгана
- External DNS суулгана
- Metrics Server суулгана

## 3. Тохиргоо Файлууд Засах

### AWS Account ID авах
```powershell
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
Write-Host "AWS Account ID: $AWS_ACCOUNT_ID"
```

### ACM Certificate үүсгэх
```powershell
# Certificate хүсэх (домэйн нэрээ солих!)
aws acm request-certificate `
  --domain-name yellowbook.your-domain.com `
  --subject-alternative-names api.yellowbook.your-domain.com `
  --validation-method DNS `
  --region us-east-1

# Certificate ARN харах
aws acm list-certificates --region us-east-1
```

### DNS Validation хийх
1. AWS Console → Certificate Manager
2. Certificate сонгох
3. "Create records in Route53" дарах
4. 5-10 минут хүлээх

## 4. Kubernetes Файлууд Засах

### Secret засах
```powershell
# k8s/secret.yaml засах
# DATABASE_URL болон JWT_SECRET солих
```

### ConfigMap засах
```powershell
# k8s/configmap.yaml засах
# NEXT_PUBLIC_API_URL: "https://api.yellowbook.YOUR-DOMAIN.com"
```

### Ingress засах
```powershell
# k8s/ingress.yaml засах
# - Certificate ARN солих
# - Домэйн нэрүүд солих
```

### aws-auth засах
```powershell
# k8s/aws-auth.yaml засах
# ACCOUNT_ID солих
```

## 5. GitHub Secret Нэмэх

1. GitHub repository → Settings → Secrets and variables → Actions
2. "New repository secret" дарах
3. Name: `AWS_ACCOUNT_ID`
4. Value: таны AWS Account ID
5. "Add secret" дарах

## 6. Deploy Хийх

### Автомат (GitHub Actions)
```powershell
git add .
git commit -m "AWS EKS deployment тохиргоо"
git push origin main
```

GitHub Actions автоматаар:
- Docker image build хийнэ
- ECR руу push хийнэ
- Kubernetes deploy хийнэ

### Гараар (локал)

#### Docker Images Build
```powershell
# ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# API image build
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest -f Dockerfile.api .

# Web image build
docker build -t ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest -f Dockerfile.web .

# Push хийх
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest
```

#### Kubernetes Deploy
```powershell
# kubeconfig шинэчлэх
aws eks update-kubeconfig --region us-east-1 --name yellowbook-cluster

# Namespace үүсгэх
kubectl apply -f k8s/namespace.yaml

# ConfigMap & Secret
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml

# PostgreSQL deploy
kubectl apply -f k8s/postgres-deployment.yaml

# PostgreSQL бэлэн болохыг хүлээх
kubectl wait --for=condition=ready pod -l app=postgres -n yellowbooks --timeout=300s

# Migration ажиллуулах
kubectl apply -f k8s/migration-job.yaml
kubectl wait --for=condition=complete job/yellowbook-migration -n yellowbooks --timeout=300s

# Image manifest-д засах
$manifestApi = Get-Content k8s/api-deployment.yaml -Raw
$manifestApi = $manifestApi -replace 'tuguu04133/yellowbook-api:latest', "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest"
$manifestApi | Set-Content k8s/api-deployment.yaml

$manifestWeb = Get-Content k8s/web-deployment.yaml -Raw
$manifestWeb = $manifestWeb -replace 'tuguu04133/yellowbook-web:latest', "${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest"
$manifestWeb | Set-Content k8s/web-deployment.yaml

# Apps deploy
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/web-deployment.yaml

# HPA & Ingress
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml

# RBAC
kubectl apply -f k8s/rbac.yaml

# Бэлэн болохыг хүлээх
kubectl rollout status deployment/yellowbook-api -n yellowbooks
kubectl rollout status deployment/yellowbook-web -n yellowbooks
```

## 7. Шалгах

```powershell
# Validation script ажиллуулах
.\scripts\validate-deployment.ps1

# Pods харах
kubectl get pods -n yellowbooks

# Services харах
kubectl get svc -n yellowbooks

# Ingress харах
kubectl get ingress -n yellowbooks

# Load Balancer URL авах
kubectl get ingress yellowbook-ingress -n yellowbooks -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# HPA харах
kubectl get hpa -n yellowbooks

# Logs харах
kubectl logs -f deployment/yellowbook-api -n yellowbooks
```

## 8. Website Хандах

DNS бэлэн болсны дараа:
- Web: https://yellowbook.your-domain.com
- API: https://api.yellowbook.your-domain.com

## Troubleshooting

### Pod ажиллахгүй байвал
```powershell
kubectl describe pod <pod-name> -n yellowbooks
kubectl logs <pod-name> -n yellowbooks
```

### Migration амжилтгүй бол
```powershell
kubectl logs job/yellowbook-migration -n yellowbooks
kubectl delete job yellowbook-migration -n yellowbooks
kubectl apply -f k8s/migration-job.yaml
```

### Metrics харагдахгүй бол
```powershell
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

## Хурдан Командууд

```powershell
# Бүх зүйл харах
kubectl get all -n yellowbooks

# Events харах
kubectl get events -n yellowbooks --sort-by='.lastTimestamp'

# Pod руу нэвтрэх
kubectl exec -it deployment/yellowbook-api -n yellowbooks -- sh

# Port forward (локал тест)
kubectl port-forward svc/yellowbook-web-service 3000:80 -n yellowbooks

# Deployment restart
kubectl rollout restart deployment/yellowbook-api -n yellowbooks
```

## Устгах

```powershell
# Namespace устгах
kubectl delete namespace yellowbooks

# Кластер устгах
eksctl delete cluster --name yellowbook-cluster --region us-east-1

# ECR repositories устгах
aws ecr delete-repository --repository-name yellowbook-api --force --region us-east-1
aws ecr delete-repository --repository-name yellowbook-web --force --region us-east-1
```

---

**Тэмдэглэл:** Бүх командыг дараалалтай ажиллуулах. Алдаа гарвал log-уудыг шалгах.
