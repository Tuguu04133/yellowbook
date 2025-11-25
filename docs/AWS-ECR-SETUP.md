# AWS ECR Setup Guide

This guide will help you set up AWS Elastic Container Registry (ECR) for the Yellow Book project.

## Prerequisites

- AWS Account (use your education account or create a new one)
- AWS CLI installed and configured
- Docker installed
- GitHub repository with appropriate permissions

## ⚠️ Cost Warning

**IMPORTANT:** ECR storage and data transfer may incur costs. Monitor your usage:
- Free tier: 500 MB storage for 12 months
- After free tier: $0.10/GB per month
- Data transfer charges may apply

To minimize costs:
- Delete old images regularly
- Use lifecycle policies to auto-delete
- Monitor AWS billing dashboard

## 1-р алхам: ECR Repository үүсгэх

### AWS CLI ашиглах

```bash
# Region-оо сонго (жишээ: us-east-1)
export AWS_REGION=us-east-1

# API repository үүсгэх
aws ecr create-repository \
    --repository-name yellowbook-api \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true

# Web repository үүсгэх
aws ecr create-repository \
    --repository-name yellowbook-web \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true
```

### AWS Console ашиглах (Илүү хялбар)

1. AWS Console руу нэвтэр
2. ECR хайж нээ
3. "Create repository" дар
4. Нэр: `yellowbook-api`
5. "Scan on push" идэвхжүүл
6. "Create repository" дар
7. `yellowbook-web`-д давтах

## 2-р алхам: Lifecycle Policy (Хуучин image устгах)

Хуучин images автоматаар устгахын тулд:

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep last 5 images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 5
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
```

Policy-г ашиглах:

```bash
aws ecr put-lifecycle-policy \
    --repository-name yellowbook-api \
    --lifecycle-policy-text file://lifecycle-policy.json

# yellowbook-web-д ч мөн адил хий
```

## 3-р алхам: GitHub-тай холбох

### Хувилбар A: IAM User (Хялбар гэхдээ анхаарал хэрэгтэй)

1. IAM user үүсгэх:

```bash
aws iam create-user --user-name github-actions-ecr
```

2. ECR эрх өгөх:

```bash
aws iam attach-user-policy \
    --user-name github-actions-ecr \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

3. Access key авах:

```bash
aws iam create-access-key --user-name github-actions-ecr
```

4. `AccessKeyId` болон `SecretAccessKey`-г хадгал

## 4-р алхам: GitHub Secrets нэмэх

### IAM User ашигласан бол:

1. GitHub repository -> Settings -> Secrets and variables -> Actions
2. Secrets нэм:
   - `AWS_ACCESS_KEY_ID`: Таны access key
   - `AWS_SECRET_ACCESS_KEY`: Таны secret key
   - `AWS_REGION`: `us-east-1` (эсвэл таны region)

## 5-р алхам: ECR Workflow идэвхжүүлэх

1. Template-г солих:

```bash
mv .github/workflows/ecr-deploy.yml.template .github/workflows/ecr-deploy.yml
```

2. Workflow файлд region-оо заа:

```yaml
env:
  AWS_REGION: us-east-
  ECR_REPOSITORY_API: yellowbook-api
  ECR_REPOSITORY_WEB: yellowbook-web
```

3. Commit хийж push хий:

```bash
git add .github/workflows/ecr-deploy.yml
git commit -m "feat: enable ECR deployment"
git push
```

## 6-р алхам: Шалгах

1. GitHub Actions шалга:
   - Actions tab руу ор
   - "Deploy to AWS ECR" workflow-г хай
   - Амжилттай ажилласан эсэхийг үз

2. ECR repositories шалга:

```bash
# API repository images
aws ecr describe-images \
    --repository-name yellowbook-api \
    --region us-east-1

# Web repository images
aws ecr describe-images \
    --repository-name yellowbook-web \
    --region us-east-1
```

## 7-р алхам: Screenshot авах (Даалгаварт хэрэгтэй)

Дараах screenshots-уудыг ав:

1. **ECR Repository List**
   - AWS Console → ECR → Repositories
   - `yellowbook-api` болон `yellowbook-web` хоёр харагдах ёстой

2. **API Repository Images**
   - `yellowbook-api` дээр дарах
   - SHA tag-тай images харуул (жишээ: `main-abc1234`)

3. **Web Repository Images**
   - `yellowbook-web` дээр дарах
   - Images харуул

4. **GitHub Actions амжилттай**
   - GitHub → Actions → Сүүлийн workflow
   - Ногоон галочка харагдах ёстой

## 8-р алхам: ECR image татаж тест хийх

```bash
# ECR руу нэвтрэх
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Images татах
docker pull YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
docker pull YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest

# Тест хийх
docker run -p 3333:3333 \
    -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
    YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
```

## Зардал хянах

### Billing Alert үүсгэх

1. AWS Billing Dashboard руу ор
2. Budget үүсгэ:
   - Нэр: "ECR Monthly Budget"
   - Дүн: $5 (эсвэл өөрийн limit)
   - Alert: 80%

### Хуучин images устгах

```bash
# Хуучин images гараар устгах
aws ecr batch-delete-image \
    --repository-name yellowbook-api \
    --image-ids imageTag=хуучин-tag
```

## Түгээмэл асуудал

### Нэвтрэх алдаа

```bash
# AWS credentials шалгах
aws sts get-caller-identity

# Дахин нэвтрэх
aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

### Image push алдаатай

- Repository үүссэн эсэхийг шалга
- IAM permissions шалга
- GitHub Secrets зөв эсэхийг шалга
- Workflow logs-г уншаад хар

### GitHub Actions амжилтгүй

- GitHub secrets зөв эсэхийг шалга
- Workflow файл syntax шалга
- AWS permissions шалга
- Logs унших

## Хэрэгтэй командууд

```bash
# Repository URI авах
aws ecr describe-repositories \
    --repository-names yellowbook-api \
    --query 'repositories[0].repositoryUri' \
    --output text

# Сүүлийн image digest авах
aws ecr describe-images \
    --repository-name yellowbook-api \
    --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' \
    --output text

# Repository устгах (БОЛГООМЖТОЙ!)
aws ecr delete-repository \
    --repository-name yellowbook-api \
    --force
```

---

**Тэмдэглэл:** Энэ даалгавар 20 оноо. Screenshot-ууд сайн авч, багшид бүх зүйлийг тодорхой харуул. Хэрэв асуудал гарвал багшаас эсвэл найзуудаасаа асуу.

**Хэмнэлттэй байгаарай:** ECR төлбөртэй! Хуучин images байнга устга.
