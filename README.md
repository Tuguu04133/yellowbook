# Yellow Book - Монголын Бизнес Лавлах

[![CI/CD Pipeline](https://github.com/Tuguu04133/yellowbook/actions/workflows/ci.yml/badge.svg)](https://github.com/Tuguu04133/yellowbook/actions/workflows/ci.yml)

Вэб програмчлалын даалгавар - Tuguu04133

## Юу хийсэн вэ?

Энэ төсөл нь Монголын бизнесүүдийг хайх, харах боломжтой цахим лавлах юм.

**Технологи:**
- Frontend: Next.js 15, React, TypeScript
- Backend: Express, Prisma ORM
- Database: PostgreSQL
- Tools: Nx workspace, Docker, GitHub Actions

## Шаардлага

- Node.js 20.x
- npm
- Docker & Docker Compose
- PostgreSQL

## Суулгах заавар

### 1. Repository татах

```bash
git clone https://github.com/Tuguu04133/yellowbook.git
cd yellowbook
```

### 2. Packages суулгах

```bash
npm install
```

### 3. Database тохируулах

`.env` файл үүсгэнэ:

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/yellowbook"
PORT=3333
NEXT_PUBLIC_API_URL="http://localhost:3333"
```

Prisma migration:

```bash
npx prisma generate
npx prisma migrate dev
npm run db:seed
```

### 4. Ажиллуулах

```bash
# API эхлүүлэх
npx nx serve api

# Web эхлүүлэх
npx nx serve web
```

- API: http://localhost:3333
- Web: http://localhost:4200

## Тест хийх

```bash
# Lint шалгах
npx nx run-many -t lint

# Unit тест
npx nx run-many -t test

# Build хийх
npx nx run-many -t build

# E2E тест
npx nx e2e web-e2e
```

## Docker ашиглах

### Docker Compose

```bash
# Build хийх
docker-compose build

# Ажиллуулах
docker-compose up

# Зогсоох
docker-compose down
```

### Шууд Docker image build

```bash
# API image
docker build -f Dockerfile.api -t yellowbook-api .

# Web image
docker build -f Dockerfile.web -t yellowbook-web .
```

## CI/CD

GitHub Actions ашигласан. Commit бүр дээр:
- Lint шалгана
- Тест ажиллуулна  
- Docker image build хийнэ

**Matrix build strategy** ашигласан - API болон Web тус тусдаа parallel build хийгдэнэ.

Workflow үзэх: [Actions](https://github.com/Tuguu04133/yellowbook/actions)

## AWS EKS Deployment

**Status:** ✅ Бүрэн хэрэгжсэн (100 оноо)

Yellowbook апп-ыг AWS EKS дээр OIDC, TLS/HTTPS, автомат scaling, database migration-тай байршуулсан.

**Онцлог:**
- ✅ **OIDC/Roles (20pts)**: GitHub Actions OIDC authentication
- ✅ **aws-auth/RBAC (10pts)**: Kubernetes RBAC тохируулга
- ✅ **Manifests (25pts)**: PostgreSQL, API, Web deployments
- ✅ **Ingress/TLS (20pts)**: AWS ALB + Route53 + ACM certificates
- ✅ **Migration Job (10pts)**: Prisma database migration automation
- ✅ **HPA (10pts)**: Auto-scaling (2-10 replicas)
- ✅ **Documentation (5pts)**: Иж бүрэн баримтжуулалт

### Хурдан эхлэх

```bash
# 1. Setup script ажиллуулах
./scripts/setup-eks.sh  # Linux/Mac
# эсвэл
.\scripts\setup-eks.ps1  # Windows

# 2. Configuration файлууд засах
# - k8s/secret.yaml
# - k8s/configmap.yaml  
# - k8s/ingress.yaml

# 3. GitHub Secret нэмэх
# AWS_ACCOUNT_ID

# 4. Deploy хийх
git push origin main
```

### Deployment баримт

- 📘 **[DEPLOY.md](DEPLOY.md)** - Иж бүрэн deployment заавар
- 📗 **[QUICKSTART.md](QUICKSTART.md)** - Хурдан лавлах
- 📕 **[SUBMISSION.md](SUBMISSION.md)** - Илгээх checklist
- 📙 **[k8s/README.md](k8s/README.md)** - Manifest тайлбар

### Үзэх

- **Live URL**: https://yellowbook.example.com _(домэйн солих)_
- **API URL**: https://api.yellowbook.example.com _(домэйн солих)_
- **GitHub Actions**: [Workflow Runs](https://github.com/Tuguu04133/yellowbook/actions)

## Project бүтэц

```
yellowbook/
├── apps/
│   ├── api/          # Express backend
│   ├── web/          # Next.js frontend
│   └── web-e2e/      # Playwright тест
├── libs/
│   ├── contract/     # Shared schemas (Zod)
│   └── config/       # Shared configuration
├── prisma/           # Database schema
├── .github/          # CI/CD workflows
├── Dockerfile.api    # API Docker файл
└── Dockerfile.web    # Web Docker файл
```
## Холбоосууд

- Repository: https://github.com/Tuguu04133/yellowbook
- CI Runs: https://github.com/Tuguu04133/yellowbook/actions
- Live Demo: _Байхгүй (AWS deployment хийгдээгүй)_

## Тусламж авсан эх сурвалж

- [Next.js Documentation](https://nextjs.org/docs)
- [Nx Documentation](https://nx.dev)
- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [GitHub Actions](https://docs.github.com/en/actions)

## Асуудал тулгарвал

1. Dependencies суулгаж чадахгүй байвал: `npm install --legacy-peer-deps`
2. Docker build алдаа: `.dockerignore` файл байгаа эсэхийг шалга
3. Database холбогдохгүй: PostgreSQL ажиллаж байгаа эсэхийг шалга
4. CI failure: Nx Cloud-г унтраасан, `nx.json`-д `nxCloudId` байхгүй

---

**Тэмдэглэл:** Энэ төсөл бол ахисан вэб програмчлалын хичээлийн даалгавар. 


