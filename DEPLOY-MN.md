# Yellowbook AWS EKS Байршуулах Заавар

Энэ заавар нь Yellowbook вэб аппликэйшныг AWS EKS (Elastic Kubernetes Service) дээр HTTPS/TLS, автомат scaling, database migration-тай хамт байршуулах бүрэн гарын авлага юм.

## Агуулга

1. [Шаардлагатай зүйлс](#шаардлагатай-зүйлс)
2. [AWS Тохиргоо](#aws-тохиргоо)
3. [OIDC Тохиргоо](#oidc-тохиргоо)
4. [EKS Кластер Үүсгэх](#eks-кластер-үүсгэх)
5. [AWS Auth & RBAC](#aws-auth--rbac)
6. [Kubernetes Манифестууд](#kubernetes-манифестууд)
7. [Ingress & TLS Тохиргоо](#ingress--tls-тохиргоо)
8. [Өгөгдлийн Сангийн Migration](#өгөгдлийн-сангийн-migration)
9. [Автомат Scaling (HPA)](#автомат-scaling-hpa)
10. [Байршуулалт](#байршуулалт)
11. [Шалгалт](#шалгалт)
12. [Асуудал Шийдвэрлэх](#асуудал-шийдвэрлэх)

---

## Шаардлагатай зүйлс

### Програм хангамжууд

- ✅ **AWS CLI** - AWS-тай харилцах
- ✅ **eksctl** - EKS кластер удирдах
- ✅ **kubectl** - Kubernetes удирдах
- ✅ **helm** - Kubernetes package удирдах
- ✅ **Docker** - Контейнер бүтээх
- ✅ **Git** - Кодын хувилбар удирдах

### AWS Данс

- AWS данс (credit card бүртгэлтэй)
- IAM эрх (Administrator эсвэл эдгээр эрхтэй)
- Route53 дээр бүртгэлтэй домэйн (эсвэл шинээр худалдаж авах)

### Мэдлэг

- Kubernetes үндсэн ойлголт
- Docker үндсэн мэдлэг
- Linux командын мөр
- YAML файл формат

---

## AWS Тохиргоо

### 1-р Алхам: EKS Кластер Үүсгэх

**Автомат арга (Зөвлөмж):**

PowerShell дээр:
```powershell
# Setup скрипт ажиллуулах
.\scripts\setup-eks.ps1
```

Linux/Mac дээр:
```bash
# Setup скрипт ажиллуулах
chmod +x scripts/setup-eks.sh
./scripts/setup-eks.sh
```

Энэ скрипт автоматаар:
- ✅ EKS кластер үүсгэнэ
- ✅ ECR repository үүсгэнэ (Docker image хадгалах)
- ✅ OIDC provider идэвхжүүлнэ
- ✅ IAM роль үүсгэнэ
- ✅ Load Balancer Controller суулгана
- ✅ External DNS суулгана
- ✅ Metrics Server суулгана

**Гараар хийх бол:**

```bash
# 1. EKS кластер үүсгэх
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

# 2. kubeconfig шинэчлэх
aws eks update-kubeconfig --region us-east-1 --name yellowbook-cluster

# 3. ECR repository үүсгэх
aws ecr create-repository --repository-name yellowbook-api --region us-east-1
aws ecr create-repository --repository-name yellowbook-web --region us-east-1
```

**Тайлбар:**
- `--name yellowbook-cluster` - Кластерын нэр
- `--region us-east-1` - AWS бүс (танай домэйнтай ижил байх ёстой)
- `--node-type t3.medium` - Node-ын төрөл (2 vCPU, 4GB RAM)
- `--nodes 3` - Анхны node тоо
- `--nodes-min 2` - Хамгийн бага node
- `--nodes-max 5` - Хамгийн их node

### 2-р Алхам: AWS Account ID Авах

```bash
# PowerShell эсвэл bash
aws sts get-caller-identity --query Account --output text
```

Жишээ гарц: `123456789012`

**Энэ дугаарыг хадгална уу!** Дараа дараа ашиглах болно.

---

## OIDC Тохиргоо

OIDC (OpenID Connect) нь GitHub Actions-с AWS руу нууц үгийн код ашиглахгүйгээр нэвтрэх боломж олгоно.

### 1-р Алхам: OIDC Provider URL Авах

```bash
# OIDC provider олох
aws eks describe-cluster \
  --name yellowbook-cluster \
  --region us-east-1 \
  --query "cluster.identity.oidc.issuer" \
  --output text
```

Жишээ гарц: `https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B716D3041E`

### 2-р Алхам: GitHub Actions-д зориулж IAM Role Үүсгэх

**Trust policy файл үүсгэх** (`github-trust-policy.json`):

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
          "token.actions.githubusercontent.com:sub": "repo:GITHUB_USERNAME/yellowbook:*"
        }
      }
    }
  ]
}
```

**Солих:**
- `ACCOUNT_ID` → Таны AWS Account ID
- `GITHUB_USERNAME` → Таны GitHub хэрэглэгчийн нэр

**Role үүсгэх:**

```bash
aws iam create-role \
  --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file://github-trust-policy.json
```

### 3-р Алхам: Эрхийн Policy Үүсгэх

**Policy файл үүсгэх** (`github-deploy-policy.json`):

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

**Policy холбох:**

```bash
aws iam put-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-name GitHubActionsDeployPolicy \
  --policy-document file://github-deploy-policy.json
```

**Тайлбар:**
- ECR эрх: Docker image хадгалах, татах
- EKS эрх: Кластер мэдээлэл унших
- STS эрх: Данс мэдээлэл шалгах

---

## EKS Кластер Үүсгэх

Хэрэв скрипт ашигласан бол энэ алхам аль хэдийн хийгдсэн. Үгүй бол:

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

**Энэ командын тайлбар:**
- Yellowbook ажиллуулах EKS кластер үүснэ
- t3.medium node (2 CPU, 4GB RAM) ашиглана
- 3 node-той эхэлж, 2-5 хооронд өөрчлөгдөнө
- OIDC provider автоматаар идэвхжинэ

**Хүлээх хугацаа:** 15-20 минут

---

## AWS Auth & RBAC

### 1-р Алхам: aws-auth ConfigMap Засах

`k8s/aws-auth.yaml` файл засах:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ТАНЫ_ACCOUNT_ID:role/YellowbookEKSNodeRole
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: arn:aws:iam::ТАНЫ_ACCOUNT_ID:role/GitHubActionsDeployRole
      username: github-actions-deployer
      groups:
        - system:masters
```

**Солих:**
- `ТАНЫ_ACCOUNT_ID` → Таны AWS Account ID

**Идэвхжүүлэх:**

```bash
kubectl apply -f k8s/aws-auth.yaml
```

**Тайлбар:**
- Энэ нь IAM role-уудыг Kubernetes user руу холбоно
- GitHub Actions role-д кластер дээр бүрэн эрх өгнө

### 2-р Алхам: RBAC Resources Үүсгэх

```bash
kubectl apply -f k8s/rbac.yaml
```

**Энэ нь үүсгэнэ:**
- ServiceAccount (yellowbook-deployer)
- Role (namespace-доторх эрхүүд)
- RoleBinding (role-ыг serviceaccount-д холбох)
- ClusterRole (кластер-даяар унших эрх)

---

## Kubernetes Манифестууд

### Файлуудын Тойм

```
k8s/
├── namespace.yaml          # yellowbooks namespace үүсгэх
├── configmap.yaml         # Тохиргооны мэдээлэл (нууцгүй)
├── secret.yaml            # Нууц мэдээлэл (нууц үг, токен)
├── postgres-deployment.yaml  # PostgreSQL өгөгдлийн сан
├── api-deployment.yaml    # Backend API
├── web-deployment.yaml    # Frontend web
├── migration-job.yaml     # Database migration
├── hpa.yaml              # Автомат scaling
├── ingress.yaml          # HTTPS/TLS тохиргоо
├── aws-auth.yaml         # AWS эрх
└── rbac.yaml             # Kubernetes эрх
```

### Засах Шаардлагатай Файлууд

#### 1. `k8s/secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: yellowbook-secrets
  namespace: yellowbooks
type: Opaque
stringData:
  DATABASE_URL: "postgresql://yellowbook:ТАНЫ_НУУЦ_ҮГ@postgres-service:5432/yellowbook?schema=public"
  JWT_SECRET: "САНАМСАРГҮЙ_УРТ_ТЕКСТ_ЭНЭ"
```

**Солих:**
- `ТАНЫ_НУУЦ_ҮГ` → Хүчтэй нууц үг үүсгэх
- `JWT_SECRET` → Санамсаргүй 32+ тэмдэгт

**Нууц үг үүсгэх:**

```bash
# PowerShell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | % {[char]$_})

# Linux/Mac
openssl rand -base64 32
```

#### 2. `k8s/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: yellowbook-config
  namespace: yellowbooks
data:
  NODE_ENV: "production"
  PORT: "3000"
  API_PORT: "3001"
  NEXT_PUBLIC_API_URL: "https://api.ТАНЫ_ДОМЭЙН.com"
```

**Солих:**
- `ТАНЫ_ДОМЭЙН.com` → Таны бодит домэйн

#### 3. `k8s/ingress.yaml`

ACM certificate ARN болон домэйн нэр солих:

```yaml
annotations:
  alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:ACCOUNT_ID:certificate/CERT_ID
  external-dns.alpha.kubernetes.io/hostname: yellowbook.ТАНЫ_ДОМЭЙН.com,api.ТАНЫ_ДОМЭЙН.com
spec:
  rules:
  - host: yellowbook.ТАНЫ_ДОМЭЙН.com
    # ...
  - host: api.ТАНЫ_ДОМЭЙН.com
    # ...
```

---

## Ingress & TLS Тохиргоо

### 1-р Алхам: AWS Load Balancer Controller Суулгах

Хэрэв setup script ажиллуулсан бол энэ аль хэдийн болсон.

**Гараар суулгах:**

```bash
# IAM policy татах
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.0/docs/install/iam_policy.json

# Policy үүсгэх
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam_policy.json

# Service account үүсгэх
eksctl create iamserviceaccount \
  --cluster=yellowbook-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region=us-east-1

# Helm ашиглан суулгах
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=yellowbook-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 2-р Алхам: ACM Certificate Хүсэх

```bash
aws acm request-certificate \
  --domain-name yellowbook.ТАНЫ_ДОМЭЙН.com \
  --subject-alternative-names api.ТАНЫ_ДОМЭЙН.com \
  --validation-method DNS \
  --region us-east-1
```

**Гарц:**
```
{
    "CertificateArn": "arn:aws:acm:us-east-1:123456789012:certificate/abc-123-def"
}
```

**Энэ ARN-г хадгална уу!**

### 3-р Алхам: DNS Баталгаажуулалт

1. AWS Console → Certificate Manager руу орох
2. Саяхан хүссэн certificate-аа сонгох
3. DNS validation records харах
4. Route53 руу орж эдгээр record-уудыг нэмэх

**Автомат (Route53 ашиглаж байвал):**
Certificate Manager дээр "Create records in Route53" товч дарах.

**Хүлээх:** 5-30 минут (DNS propagation)

### 4-р Алхам: External DNS Суулгах

Route53 дээр автоматаар DNS record үүсгэнэ.

```bash
# IAM policy үүсгэх
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

# Service account үүсгэх
eksctl create iamserviceaccount \
  --cluster=yellowbook-cluster \
  --namespace=kube-system \
  --name=external-dns \
  --attach-policy-arn=arn:aws:iam::ACCOUNT_ID:policy/ExternalDNSPolicy \
  --approve \
  --region=us-east-1
```

External DNS deployment үүсгэх - `setup-eks` скрипт үүнийг автоматаар хийнэ.

---

## Өгөгдлийн Сангийн Migration

### Migration Job Тайлбар

`k8s/migration-job.yaml` файл нь:

1. **PostgreSQL хүлээнэ** - Init container PostgreSQL бэлэн эсэхийг шалгана
2. **Migration ажиллуулна** - `npx prisma migrate deploy` командыг ажиллуулна
3. **Автомат цэвэрлэнэ** - 5 минутын дараа job устана

### Гараар Migration Ажиллуулах

```bash
# Хуучин job устгах
kubectl delete job yellowbook-migration -n yellowbooks --ignore-not-found=true

# Шинэ job үүсгэх
kubectl apply -f k8s/migration-job.yaml

# Явцыг харах
kubectl get jobs -n yellowbooks -w

# Log харах
kubectl logs -n yellowbooks job/yellowbook-migration

# Дэлгэрэнгүй мэдээлэл
kubectl describe job yellowbook-migration -n yellowbooks
```

### Database Seed (Өгөгдөл оруулах)

```bash
kubectl run seed-job \
  --image=ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest \
  -n yellowbooks \
  --rm -it --restart=Never \
  --env="DATABASE_URL=$(kubectl get secret yellowbook-secrets -n yellowbooks -o jsonpath='{.data.DATABASE_URL}' | base64 -d)" \
  -- npx prisma db seed
```

---

## Автомат Scaling (HPA)

### HPA Тохиргоо

API болон Web аппликэйшн хоёуланд нь автомат scaling идэвхтэй:

**Үндсэн тохиргоо:**
- **Хамгийн бага replicas:** 2
- **Хамгийн их replicas:** 10
- **CPU зорилт:** 70% ашиглалт
- **Memory зорилт:** 80% ашиглалт

### Scale-Up Бодлого

Ачаалал ихэсвэл:
- 30 секунд бүр 100% эсвэл 2 pod нэмнэ (аль нь их байвал)
- Хамгийн их 10 pod хүртэл нэмэгдэнэ

### Scale-Down Бодлого

Ачаалал багассан үед:
- 60 секунд бүр 50%-иар бууруулна
- 5 минутын stabilization период (зөрүү ихээр хэлбэлзэхээс сэргийлнэ)
- Хамгийн багадаа 2 pod үлдэнэ

### HPA Хянах

```bash
# HPA статус харах
kubectl get hpa -n yellowbooks

# Дэлгэрэнгүй мэдээлэл
kubectl describe hpa yellowbook-api-hpa -n yellowbooks
kubectl describe hpa yellowbook-web-hpa -n yellowbooks

# Бодит цагт хянах
kubectl get hpa -n yellowbooks -w
```

### Scaling Туршилт Хийх

```bash
# hey load generator суулгах (Go ашиглана)
# https://github.com/rakyll/hey

# Ачаалал үүсгэх
hey -z 5m -c 50 https://api.ТАНЫ_ДОМЭЙН.com/api/yellow-books

# Өөр terminal дээр scaling харах
kubectl get hpa -n yellowbooks -w
```

**Харах зүйлс:**
- CPU/Memory ашиглалт өснө
- TARGET багана хэтэрнэ (70%/80%)
- REPLICAS багана өснө (2 → 3 → 4 ...)

---

## Байршуулалт

### GitHub Secrets Тохируулах

1. GitHub repository руу орох
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret** дарах
4. Нэмэх:
   - Name: `AWS_ACCOUNT_ID`
   - Value: Таны AWS Account ID

### Автомат Байршуулалт (GitHub Actions)

1. **Бүх файл засварлах:**
   - `k8s/secret.yaml` - Нууц үгс
   - `k8s/configmap.yaml` - Домэйн
   - `k8s/ingress.yaml` - Certificate ARN
   - `k8s/aws-auth.yaml` - Account ID

2. **Commit хийх:**
   ```bash
   git add .
   git commit -m "AWS EKS deployment тохиргоо"
   git push origin main
   ```

3. **GitHub Actions ажиллана:**
   - Code татана
   - OIDC ашиглан AWS-д нэвтэрнэ
   - Docker image build хийнэ
   - ECR руу push хийнэ
   - PostgreSQL deploy хийнэ
   - Migration ажиллуулна
   - API & Web deploy хийнэ
   - HPA & Ingress deploy хийнэ

4. **Явцыг харах:**
   - GitHub → Actions tab
   - Сүүлийн workflow run-г харах

### Гараар Байршуулах

```bash
# 1. Docker images build хийх
docker build -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest -f Dockerfile.api .
docker build -t ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest -f Dockerfile.web .

# 2. ECR руу нэвтрэх
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 3. Push хийх
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
docker push ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest

# 4. Kubernetes manifests идэвхжүүлэх
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/postgres-deployment.yaml

# 5. PostgreSQL хүлээх
kubectl wait --for=condition=ready pod -l app=postgres -n yellowbooks --timeout=300s

# 6. Migration ажиллуулах
kubectl apply -f k8s/migration-job.yaml
kubectl wait --for=condition=complete job/yellowbook-migration -n yellowbooks --timeout=300s

# 7. Апп-уудыг deploy хийх
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/web-deployment.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml

# 8. Бэлэн болохыг хүлээх
kubectl rollout status deployment/yellowbook-api -n yellowbooks
kubectl rollout status deployment/yellowbook-web -n yellowbooks
```

---

## Шалгалт

### 1. Pod-уудыг Шалгах

```bash
kubectl get pods -n yellowbooks
```

**Хүлээгдэж буй гарц:**
```
NAME                              READY   STATUS    RESTARTS   AGE
postgres-xxx                      1/1     Running   0          5m
yellowbook-api-xxx                1/1     Running   0          2m
yellowbook-api-yyy                1/1     Running   0          2m
yellowbook-web-xxx                1/1     Running   0          2m
yellowbook-web-yyy                1/1     Running   0          2m
```

**Шалгах:**
- ✅ Бүх pod "Running" төлөвт байна
- ✅ READY багана 1/1 байна
- ✅ Хамгийн багадаа 2 API pod, 2 Web pod байна

### 2. Service-үүдийг Шалгах

```bash
kubectl get svc -n yellowbooks
```

### 3. Ingress Шалгах

```bash
kubectl get ingress -n yellowbooks
kubectl describe ingress yellowbook-ingress -n yellowbooks
```

**Load Balancer URL авах:**
```bash
kubectl get ingress yellowbook-ingress -n yellowbooks -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### 4. HPA Шалгах

```bash
kubectl get hpa -n yellowbooks
```

**Хүлээгдэж буй гарц:**
```
NAME                 REFERENCE                   TARGETS         MINPODS   MAXPODS   REPLICAS
yellowbook-api-hpa   Deployment/yellowbook-api   45%/70%, 60%/80%   2         10        2
yellowbook-web-hpa   Deployment/yellowbook-web   50%/70%, 55%/80%   2         10        2
```

### 5. Log-ууд Харах

```bash
# API logs
kubectl logs -f deployment/yellowbook-api -n yellowbooks

# Web logs
kubectl logs -f deployment/yellowbook-web -n yellowbooks

# Migration logs
kubectl logs job/yellowbook-migration -n yellowbooks

# PostgreSQL logs
kubectl logs deployment/postgres -n yellowbooks
```

### 6. Апп Туршилт Хийх

DNS тохируулсны дараа:

**Web хандах:**
```
https://yellowbook.ТАНЫ_ДОМЭЙН.com
```

**API шалгах:**
```bash
curl https://api.ТАНЫ_ДОМЭЙН.com/api/yellow-books
```

**Browser дээр шалгах:**
- HTTPS ажиллаж байна уу?
- Цоож (🔒) үзэгдэж байна уу?
- Certificate алдаагүй юу?

### 7. Автомат Validation Script

```bash
# PowerShell
.\scripts\validate-deployment.ps1

# Linux/Mac
./scripts/validate-deployment.sh
```

Энэ скрипт автоматаар:
- ✅ Бүх pod-уудыг шалгана
- ✅ Service-үүдийг шалгана
- ✅ Ingress тохиргоог шалгана
- ✅ HPA ажиллаж байгаа эсэхийг шалгана
- ✅ Migration амжилттай болсон эсэхийг шалгана

### 8. Screenshot Авах (Илгээх шаардлага)

#### Screenshot 1: HTTPS + Padlock

1. Browser нээх
2. `https://yellowbook.ТАНЫ_ДОМЭЙН.com` руу орох
3. URL хаягийн дэргэдэх цоожийг дарж certificate харах
4. Screenshot авах - URL bar + цоож харагдана

#### Screenshot 2: GitHub Actions Success

1. GitHub → Actions tab
2. Сүүлийн workflow run
3. Бүх step амжилттай (ногоон тэмдэг)
4. Screenshot авах

#### Screenshot 3: kubectl get pods

```bash
kubectl get pods -n yellowbooks
```

Terminal-ын screenshot авах - бүх pod "Running" төлөвт байна.

---

## Асуудал Шийдвэрлэх

### Pod Эхлэхгүй Байна

```bash
# Pod-ын дэлгэрэнгүй мэдээлэл
kubectl describe pod <pod-name> -n yellowbooks

# Log харах
kubectl logs <pod-name> -n yellowbooks

# Events харах
kubectl get events -n yellowbooks --sort-by='.lastTimestamp'
```

**Түгээмэл асуудлууд:**
- Image pull хийж чадахгүй: ECR эрх шалгах
- Database холбогдохгүй: PostgreSQL ажиллаж байгаа эсэхийг шалгах
- Config алдаа: ConfigMap болон Secret зөв эсэхийг шалгах

### Database Холболтын Асуудал

```bash
# PostgreSQL log
kubectl logs deployment/postgres -n yellowbooks

# Secret шалгах
kubectl get secret yellowbook-secrets -n yellowbooks -o yaml

# API pod-оос шалгах
kubectl exec -it deployment/yellowbook-api -n yellowbooks -- sh
# Container дотор:
env | grep DATABASE_URL
```

### Migration Job Амжилтгүй

```bash
# Migration log харах
kubectl logs job/yellowbook-migration -n yellowbooks

# Job устгаж дахин эхлүүлэх
kubectl delete job yellowbook-migration -n yellowbooks
kubectl apply -f k8s/migration-job.yaml

# Дахин туршилт хийх
kubectl wait --for=condition=complete job/yellowbook-migration -n yellowbooks --timeout=300s
```

**Шалгах зүйлс:**
- DATABASE_URL зөв эсэх
- PostgreSQL ажиллаж байгаа эсэх
- Migration файлууд байгаа эсэх

### Ingress Ажиллахгүй Байна

```bash
# Load Balancer Controller log
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Ingress дэлгэрэнгүй
kubectl describe ingress yellowbook-ingress -n yellowbooks

# AWS Console дээр ALB шалгах
# EC2 → Load Balancers
```

**Шалгах:**
- Certificate ARN зөв эсэх
- Домэйн нэр зөв эсэх
- Load Balancer үүссэн эсэх

### HPA Scaling Хийхгүй Байна

```bash
# Metrics харах
kubectl top nodes
kubectl top pods -n yellowbooks
```

**Metrics байхгүй бол:**

```bash
# Metrics Server суулгах
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Metrics Server log
kubectl logs -n kube-system deployment/metrics-server
```

### DNS Ажиллахгүй Байна

```bash
# External DNS log
kubectl logs -n kube-system deployment/external-dns

# Route53 шалгах
aws route53 list-resource-record-sets --hosted-zone-id ТАНЫ_ZONE_ID
```

**Шийдэл:**
- External DNS ажиллаж байгаа эсэхийг шалгах
- Route53 Hosted Zone зөв эсэхийг шалгах
- Domain NS records зөв эсэхийг шалгах

---

## Цэвэрлэх (Устгах)

Бүх зүйлийг устгах:

```bash
# 1. Kubernetes resources устгах
kubectl delete namespace yellowbooks

# 2. Load Balancer Controller устгах
helm uninstall aws-load-balancer-controller -n kube-system

# 3. External DNS устгах
kubectl delete deployment external-dns -n kube-system

# 4. EKS кластер устгах
eksctl delete cluster --name yellowbook-cluster --region us-east-1

# 5. ECR repositories устгах
aws ecr delete-repository --repository-name yellowbook-api --force --region us-east-1
aws ecr delete-repository --repository-name yellowbook-web --force --region us-east-1

# 6. IAM roles устгах
aws iam delete-role-policy --role-name GitHubActionsDeployRole --policy-name GitHubActionsDeployPolicy
aws iam delete-role --role-name GitHubActionsDeployRole
```

---

## Илгээх Checklist

### OIDC/Roles (20 оноо)
- [ ] IAM OIDC provider идэвхтэй
- [ ] GitHub Actions IAM role үүссэн
- [ ] Trust policy зөв тохируулагдсан
- [ ] AWS нууц үг ашиглаагүй

### aws-auth/RBAC (10 оноо)
- [ ] aws-auth ConfigMap тохируулагдсан
- [ ] ServiceAccount үүссэн
- [ ] Role болон RoleBinding үүссэн

### Manifests (25 оноо)
- [ ] Namespace үүссэн
- [ ] ConfigMap болон Secret тохируулагдсан
- [ ] PostgreSQL deployment бүрэн
- [ ] API болон Web deployment 2+ replica
- [ ] Service-үүд үүссэн
- [ ] Health check тохируулагдсан

### Ingress/TLS (20 оноо)
- [ ] Load Balancer Controller суулгасан
- [ ] ACM certificate үүссэн болон баталгаажсан
- [ ] Ingress TLS-тай тохируулагдсан
- [ ] External DNS ажиллаж байна
- [ ] HTTPS цоож харагдаж байна

### Migration Job (10 оноо)
- [ ] Migration job manifest үүссэн
- [ ] Job амжилттай ажилладаг
- [ ] Database schema шинэчлэгдсэн

### HPA (10 оноо)
- [ ] HPA API-д тохируулагдсан
- [ ] HPA Web-д тохируулагдсан
- [ ] Metrics Server суулгасан
- [ ] Scaling ажиллаж байна

### Docs (5 оноо)
- [ ] DEPLOY.md бүрэн
- [ ] OIDC тохиргоо баримтжуулсан
- [ ] Manifest тайлбар бичсэн
- [ ] Troubleshooting заавар байна

### Screenshots
- [ ] HTTPS + padlock screenshot
- [ ] GitHub Actions амжилттай ажилласан screenshot
- [ ] `kubectl get pods -n yellowbooks` screenshot

---

## Хурдан Лавлах Командууд

```bash
# Pod-уудыг харах
kubectl get pods -n yellowbooks

# Log харах
kubectl logs -f deployment/yellowbook-api -n yellowbooks

# Service-үүд харах
kubectl get svc -n yellowbooks

# Ingress харах
kubectl get ingress -n yellowbooks

# HPA харах
kubectl get hpa -n yellowbooks

# Events харах
kubectl get events -n yellowbooks --sort-by='.lastTimestamp'

# Pod руу нэвтрэх
kubectl exec -it deployment/yellowbook-api -n yellowbooks -- sh

# Port forward (локал тест)
kubectl port-forward svc/yellowbook-api-service 3001:80 -n yellowbooks

# Deployment restart
kubectl rollout restart deployment/yellowbook-api -n yellowbooks

# Scaling гараар
kubectl scale deployment yellowbook-api --replicas=5 -n yellowbooks

# Metrics харах
kubectl top nodes
kubectl top pods -n yellowbooks
```

---

## Холбоосууд болон Нөөцүүд

- 📘 [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- 📗 [Kubernetes Docs (Монгол)](https://kubernetes.io/mn/)
- 📕 [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- 📙 [Prisma Documentation](https://www.prisma.io/docs/)
- 🎥 [EKS Workshop](https://www.eksworkshop.com/)

---

## Дүгнэлт

Энэ заавар дагаад та:

✅ AWS EKS кластер үүсгэсэн  
✅ OIDC authentication тохируулсан  
✅ Kubernetes manifests бүтээсэн  
✅ HTTPS/TLS идэвхжүүлсэн  
✅ Автомат scaling тохируулсан  
✅ Database migration автоматжуулсан  
✅ CI/CD pipeline бүтээсэн  

**Амжилт хүсье! 🚀**

Асуудал гарвал:
1. Validation script ажиллуулах
2. Log-уудыг шалгах
3. Events-үүдийг харах
4. Troubleshooting бүлэг унших

---

**Он сар өдөр:** 2025-12-08  
**Хувилбар:** 1.0  
**Зохиогч:** GitHub Copilot
