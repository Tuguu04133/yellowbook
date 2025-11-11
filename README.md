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
- GitHub Container Registry руу push хийнэ

**Matrix build strategy** ашигласан - API болон Web тус тусдаа parallel build хийгдэнэ.

Workflow үзэх: [Actions](https://github.com/Tuguu04133/yellowbook/actions)

## AWS ECR Deploy

**Note:** AWS ECR байршуулах даалгавар хараахан хийгдээгүй (20 оноо). 

Template бэлдсэн:
- `docs/AWS-ECR-SETUP.md` - Дэлгэрэнгүй заавар
- `.github/workflows/ecr-deploy.yml.template` - Workflow template

Хэрэв хийх бол:
1. ECR repositories үүсгэ
2. IAM policy тохируул  
3. GitHub Secrets нэм
4. Template файлыг activate хий

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
- AI: GitHub Copilot, ChatGPT (кодын зарим хэсэг)

## Асуудал тулгарвал

1. Dependencies суулгаж чадахгүй байвал: `npm install --legacy-peer-deps`
2. Docker build алдаа: `.dockerignore` файл байгаа эсэхийг шалга
3. Database холбогдохгүй: PostgreSQL ажиллаж байгаа эсэхийг шалга
4. CI failure: Nx Cloud-г унтраасан, `nx.json`-д `nxCloudId` байхгүй

---

**Тэмдэглэл:** Энэ төсөл бол вэб програмчлалын хичээлийн даалгавар. 


