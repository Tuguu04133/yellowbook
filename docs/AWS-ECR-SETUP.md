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

## Step 1: Create ECR Repositories

### Using AWS CLI

```bash
# Set your AWS region
export AWS_REGION=us-east-1

# Create API repository
aws ecr create-repository \
    --repository-name yellowbook-api \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256

# Create Web repository
aws ecr create-repository \
    --repository-name yellowbook-web \
    --region $AWS_REGION \
    --image-scanning-configuration scanOnPush=true \
    --encryption-configuration encryptionType=AES256
```

### Using AWS Console

1. Go to Amazon ECR in AWS Console
2. Click "Create repository"
3. Repository name: `yellowbook-api`
4. Enable "Scan on push"
5. Enable "KMS encryption" (optional)
6. Click "Create repository"
7. Repeat for `yellowbook-web`

## Step 2: Set Up Lifecycle Policies

Create lifecycle policies to automatically delete old images and reduce costs:

### API Repository Lifecycle Policy

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

Apply the policy:

```bash
aws ecr put-lifecycle-policy \
    --repository-name yellowbook-api \
    --lifecycle-policy-text file://lifecycle-policy.json
```

Repeat for `yellowbook-web`.

## Step 3: Set Up Repository Permissions

### Option A: IAM User (Simpler, less secure)

1. Create IAM user with ECR permissions:

```bash
aws iam create-user --user-name github-actions-ecr
```

2. Attach ECR permissions:

```bash
aws iam attach-user-policy \
    --user-name github-actions-ecr \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

3. Create access keys:

```bash
aws iam create-access-key --user-name github-actions-ecr
```

4. Save the `AccessKeyId` and `SecretAccessKey`

### Option B: OIDC (Recommended, more secure)

1. Create an OIDC provider for GitHub:

```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

2. Create an IAM role for GitHub Actions:

Create `trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
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

```bash
aws iam create-role \
    --role-name GitHubActionsECRRole \
    --assume-role-policy-document file://trust-policy.json
```

3. Attach ECR permissions:

```bash
aws iam attach-role-policy \
    --role-name GitHubActionsECRRole \
    --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser
```

## Step 4: Configure GitHub Secrets

### For Option A (IAM User):

1. Go to your GitHub repository
2. Settings → Secrets and variables → Actions
3. Add secrets:
   - `AWS_ACCESS_KEY_ID`: Your access key ID
   - `AWS_SECRET_ACCESS_KEY`: Your secret access key
   - `AWS_REGION`: `us-east-1` (or your region)

### For Option B (OIDC):

1. Add secret:
   - `AWS_ROLE_TO_ASSUME`: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsECRRole`
   - `AWS_REGION`: `us-east-1` (or your region)

## Step 5: Enable ECR Workflow

1. Rename the template:

```bash
mv .github/workflows/ecr-deploy.yml.template .github/workflows/ecr-deploy.yml
```

2. Update environment variables in the workflow:

```yaml
env:
  AWS_REGION: us-east-1  # Your region
  ECR_REPOSITORY_API: yellowbook-api
  ECR_REPOSITORY_WEB: yellowbook-web
```

3. Choose authentication method (comment/uncomment lines in workflow)

4. Commit and push:

```bash
git add .github/workflows/ecr-deploy.yml
git commit -m "feat: enable ECR deployment"
git push
```

## Step 6: Verify Deployment

1. Check GitHub Actions:
   - Go to Actions tab in your repository
   - Look for "Deploy to AWS ECR" workflow
   - Verify it runs successfully

2. Check ECR repositories:

```bash
# List images in API repository
aws ecr describe-images \
    --repository-name yellowbook-api \
    --region $AWS_REGION

# List images in Web repository
aws ecr describe-images \
    --repository-name yellowbook-web \
    --region $AWS_REGION
```

3. Get specific image with SHA tag:

```bash
# Get image URI
aws ecr describe-images \
    --repository-name yellowbook-api \
    --image-ids imageTag=main-<commit-sha> \
    --region $AWS_REGION
```

## Step 7: Screenshots for Deliverables

Take screenshots of:

1. **ECR Repository List**
   - AWS Console → ECR → Repositories
   - Show both `yellowbook-api` and `yellowbook-web`

2. **API Repository Images**
   - Click on `yellowbook-api`
   - Show images with SHA tags (e.g., `main-abc1234`)

3. **Web Repository Images**
   - Click on `yellowbook-web`
   - Show images with SHA tags

4. **GitHub Actions Success**
   - GitHub → Actions → Latest workflow run
   - Show green checkmarks

## Step 8: Pull and Test ECR Images

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Pull images
docker pull YOUR_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/yellowbook-api:latest
docker pull YOUR_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/yellowbook-web:latest

# Test images
docker run -p 3333:3333 \
    -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
    YOUR_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/yellowbook-api:latest

docker run -p 3000:3000 \
    -e NEXT_PUBLIC_API_URL="http://localhost:3333" \
    YOUR_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/yellowbook-web:latest
```

## Monitoring Costs

### Set Up Billing Alerts

1. Go to AWS Billing Dashboard
2. Create a budget:
   - Budget name: "ECR Monthly Budget"
   - Amount: $5 (or your limit)
   - Alert threshold: 80%

### Monitor ECR Usage

```bash
# Get repository metrics
aws ecr describe-repositories --repository-names yellowbook-api yellowbook-web

# List all images with sizes
aws ecr describe-images \
    --repository-name yellowbook-api \
    --query 'sort_by(imageDetails,& imagePushedAt)[*].[imageTags[0],imageSizeInBytes,imagePushedAt]' \
    --output table
```

### Clean Up Old Images

```bash
# Delete images older than 30 days (manual)
aws ecr batch-delete-image \
    --repository-name yellowbook-api \
    --image-ids imageTag=old-tag
```

## Troubleshooting

### Authentication Failed

```bash
# Check AWS credentials
aws sts get-caller-identity

# Re-authenticate Docker
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

### Image Push Failed

- Check repository exists
- Verify IAM permissions
- Check image tag format
- Verify network connectivity

### GitHub Actions Failing

- Check GitHub secrets are set correctly
- Verify workflow syntax
- Check AWS permissions
- Review workflow logs

## Next Steps: EKS Deployment

After ECR setup is complete, you'll be ready for EKS deployment:

1. Create EKS cluster
2. Configure kubectl
3. Create Kubernetes manifests
4. Deploy from ECR to EKS
5. Set up ingress and load balancer

This will be covered in next week's assignment.

## Useful Commands

```bash
# Get repository URI
aws ecr describe-repositories \
    --repository-names yellowbook-api \
    --query 'repositories[0].repositoryUri' \
    --output text

# Get latest image digest
aws ecr describe-images \
    --repository-name yellowbook-api \
    --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageDigest' \
    --output text

# Delete repository (careful!)
aws ecr delete-repository \
    --repository-name yellowbook-api \
    --force
```

## References

- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [GitHub Actions AWS Credentials](https://github.com/aws-actions/configure-aws-credentials)
- [Docker Build and Push](https://github.com/docker/build-push-action)
