# Assignment Completion Checklist

This checklist helps you verify that all assignment requirements are completed.

## 📋 Assignment Requirements

### ✅ Dockerfiles (30 points)

- [x] Create `Dockerfile.api` with multi-stage build
  - [x] Builder stage for compilation
  - [x] Runner stage for production
  - [x] Proper dependency installation
  - [x] Prisma Client generation
  - [x] Health check configuration
  - [x] Non-root user (optional but recommended)

- [x] Create `Dockerfile.web` with multi-stage build
  - [x] Builder stage for Next.js build
  - [x] Runner stage for production
  - [x] Standalone output configuration
  - [x] Health check configuration
  - [x] Proper file copying

- [x] Create `.dockerignore` file
  - [x] Exclude node_modules
  - [x] Exclude build artifacts
  - [x] Exclude development files

### ✅ Local Sanity (10 points)

- [ ] Test API Docker build locally
  ```bash
  .\scripts\docker-test.ps1 api
  ```

- [ ] Web Docker build тест
  ```bash
  .\scripts\docker-test.ps1 web
  ```

- [ ] Docker Compose тест
  ```bash
  docker-compose up --build
  ```

- [ ] Health checks шалгах
  - [ ] API: `http://localhost:3333/`
  - [ ] Web: `http://localhost:3000/`

- [ ] API endpoints тест
  - [ ] GET `/yellow-books`
  - [ ] GET `/yellow-books/:id`
  - [ ] POST `/yellow-books`

### ⏳ ECR Repos + Policies (20 оноо)

⚠️ **ЭНЭ ХЭСГИЙГ ХИЙ - AWS Setup хэрэгтэй**

- [ ] AWS ECR repositories үүсгэх
  - [ ] `yellowbook-api` repository
  - [ ] `yellowbook-web` repository
  
- [ ] Repository тохиргоо
  - [ ] Scan on push идэвхжүүлэх
  - [ ] Encryption тохируулах
  
- [ ] Lifecycle policies
  - [ ] Сүүлийн 5 image хадгалах
  - [ ] Хуучин images автоматаар устгах
  
- [ ] IAM permissions
  - [ ] IAM user үүсгэх эсвэл
  - [ ] OIDC тохируулах (recommended)
  
- [ ] GitHub secrets нэмэх
  - [ ] `AWS_ROLE_TO_ASSUME` эсвэл
  - [ ] `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY`
  - [ ] `AWS_REGION`

- [ ] ECR workflow идэвхжүүлэх
  ```bash
  mv .github/workflows/ecr-deploy.yml.template .github/workflows/ecr-deploy.yml
  ```

### ✅ CI Build/Push (30 оноо)

- [x] GitHub Actions workflow
  - [x] Main/develop руу push
  - [x] Pull requests дээр ажилла
  - [x] Code quality checks
  - [x] Tests ажиллуулна
  - [x] Build хийнэ

- [x] Docker build and push
  - [x] API Docker image build
  - [x] Web Docker image build
  - [x] GHCR руу push
  - [x] SHA tag
  - [x] Branch tag
  - [x] 'latest' tag

- [ ] GitHub руу push хийх
  ```bash
  git add .
  git commit -m "feat: add Docker support and CI/CD pipeline"
  git push origin main
  ```

- [ ] Verify CI runs successfully
  - [ ] Check Actions tab
  - [ ] All jobs green ✅
  - [ ] Docker images pushed

### ✅ Docs (10 points)

- [x] Update README.md
  - [x] Add CI/CD badge
  - [x] Add project description
  - [x] Add features list
  - [x] Add prerequisites
  - [x] Add getting started guide
  - [x] Add development instructions
  - [x] Add Docker instructions
  - [x] Add CI/CD documentation
  - [x] Add deployment guide
  - [x] Add project structure
  - [x] Add scripts documentation
  - [x] Add technology stack

- [x] Create additional documentation
  - [x] `docs/AWS-ECR-SETUP.md` - ECR setup guide
  - [x] `docs/LOCAL-TESTING.md` - Local testing guide
  - [x] `CONTRIBUTING.md` - Contribution guidelines

- [x] Create helper scripts
  - [x] `scripts/docker-test.sh` - Bash test script
  - [x] `scripts/docker-test.ps1` - PowerShell test script

### ✅ Bonus (+10 points = 1 point)

- [x] Matrix build strategy
  - [x] Build both API and Web in parallel
  - [x] Works for both push and pull_request events
  - [x] Optimized caching

- [x] Health check reports
  - [x] Automated health check testing
  - [x] Generate reports as artifacts
  - [x] Include in workflow summary

## 🎯 Deliverables

### 1. Repository Link

- [ ] Make repository public (or give access to instructor)
- [ ] Repository URL: `https://github.com/Tuguu04133/yellowbook`

### 2. CI Run Link

- [ ] GitHub Actions run with green checkmarks
- [ ] CI URL: `https://github.com/Tuguu04133/yellowbook/actions`
- [ ] Latest successful run link: `_________________`

### 3. ECR Screenshots

Take screenshots of:

- [ ] ECR repository list (showing both repositories)
  - Screenshot filename: `ecr-repositories.png`

- [ ] API repository images with SHA tags
  - Screenshot filename: `ecr-api-images.png`
  - Must show image tagged with commit SHA

- [ ] Web repository images with SHA tags
  - Screenshot filename: `ecr-web-images.png`
  - Must show image tagged with commit SHA

### 4. Updated README Badge

- [x] CI/CD badge showing build status
  ```markdown
  [![CI/CD Pipeline](https://github.com/Tuguu04133/yellowbook/actions/workflows/ci.yml/badge.svg)](https://github.com/Tuguu04133/yellowbook/actions/workflows/ci.yml)
  ```

## 📝 Submission Checklist

Before submitting:

- [ ] All code committed and pushed to GitHub
- [ ] CI pipeline runs successfully (green)
- [ ] Docker images in GHCR tagged with SHA
- [ ] AWS ECR repositories created and configured
- [ ] Docker images in ECR tagged with SHA
- [ ] Screenshots taken and ready
- [ ] README badges updated
- [ ] Documentation complete

## 🚀 Quick Test Commands

Run these to verify everything works:

```bash
# 1. Local build
.\scripts\docker-test.ps1 all

# 2. Docker Compose
docker-compose up -d
curl http://localhost:3333/
curl http://localhost:3000/
docker-compose down

# 3. Code quality
npm run lint
npm run format:check

# 4. Build
npx nx run-many -t build

# 5. Git push (CI ажиллана)
git add .
git commit -m "feat: complete assignment"
git push origin main

# 6. CI шалгах
# https://github.com/Tuguu04133/yellowbook/actions
```

## Оноо

| Даалгавар | Оноо | Статус |
|----------|--------|--------|
| Dockerfiles | 30 | ✅ |
| Local sanity | 10 | ⏳ |
| ECR repos | 20 | ⏳ |
| CI build/push | 30 | ✅ |
| Docs | 10 | ✅ |
| **Subtotal** | **100** | |
| **Bonus** | **+10** | ✅ |
| **Total** | **110** | |

## Дараагийн долоо хоног

EKS deployment:
- EKS cluster үүсгэх
- ECR-с Kubernetes руу deploy хийх
- Ingress, load balancer
- Auto-scaling
- Monitoring

---

**Амжилт хүсье! 🚀**
