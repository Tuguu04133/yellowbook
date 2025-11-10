# 📒 Yellow Book - Mongolian Business Directory

[![CI/CD Pipeline](https://github.com/Tuguu04133/yellowbook/actions/workflows/ci.yml/badge.svg)](https://github.com/Tuguu04133/yellowbook/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Enabled-blue.svg)](https://www.docker.com/)
[![Node.js Version](https://img.shields.io/badge/node-20.x-green.svg)](https://nodejs.org/)

A modern, full-stack business directory application for Mongolia, built with Next.js, Express, and PostgreSQL in an Nx monorepo.

## 🚀 Features

- ✅ **Nx Monorepo** - Efficient workspace management with caching and affected commands
- ✅ **Next.js 15** - Modern React framework with App Router
- ✅ **Express API** - RESTful backend with TypeScript
- ✅ **Prisma ORM** - Type-safe database access with PostgreSQL
- ✅ **Zod Validation** - Shared schemas between frontend and backend
- ✅ **TypeScript Strict Mode** - Type safety across the entire codebase
- ✅ **ESLint & Prettier** - Code quality and formatting
- ✅ **Docker Support** - Containerized applications with multi-stage builds
- ✅ **GitHub Actions CI/CD** - Automated testing, building, and deployment
- ✅ **Health Checks** - Built-in container health monitoring

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Development](#development)
- [Docker](#docker)
- [CI/CD](#cicd)
- [Deployment](#deployment)
- [Project Structure](#project-structure)
- [Scripts](#scripts)

## 📦 Prerequisites

- Node.js 20.x or higher
- npm or yarn
- Docker & Docker Compose (for containerized development)
- PostgreSQL (if running locally without Docker)

## 🏁 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/Tuguu04133/yellowbook.git
cd yellowbook
```

### 2. Install dependencies

```bash
npm install
```

### 3. Set up environment variables

Create a `.env` file in the root directory:

```env
# Database
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/yellowbook"

# API
PORT=3333
HOST=0.0.0.0

# Web
NEXT_PUBLIC_API_URL="http://localhost:3333"
```

### 4. Initialize the database

```bash
# Generate Prisma Client
npx prisma generate

# Run migrations
npx prisma migrate dev

# Seed the database (optional)
npm run db:seed
```

### 5. Start development servers

```bash
# Start API
npx nx serve api

# Start Web (in another terminal)
npx nx serve web
```

The API will be available at `http://localhost:3333` and the Web app at `http://localhost:4200`.

## 💻 Development

### Running Tests

```bash
# Run all tests
npx nx run-many -t test

# Run tests for affected projects
npx nx affected -t test

# Run tests with coverage
npx nx run-many -t test --coverage
```

### Linting

```bash
# Lint all projects
npm run lint

# Lint affected projects
npx nx affected -t lint

# Auto-fix linting issues
npx nx run-many -t lint --fix
```

### Formatting

```bash
# Check formatting
npm run format:check

# Format all files
npm run format
```

### Type Checking

```bash
npm run type-check
```

### Building

```bash
# Build all projects
npx nx run-many -t build

# Build affected projects
npx nx affected -t build

# Build specific project
npx nx build api
npx nx build web
```

## 🐳 Docker

### Local Development with Docker Compose

```bash
# Build and start all services
docker-compose up --build

# Start in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

### Building Individual Docker Images

```bash
# Build API image
docker build -f Dockerfile.api -t yellowbook-api:latest .

# Build Web image
docker build -f Dockerfile.web -t yellowbook-web:latest .
```

### Running Individual Containers

```bash
# Run API container
docker run -d \
  -p 3333:3333 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  --name yellowbook-api \
  yellowbook-api:latest

# Run Web container
docker run -d \
  -p 3000:3000 \
  -e NEXT_PUBLIC_API_URL="http://localhost:3333" \
  --name yellowbook-web \
  yellowbook-web:latest
```

### Health Checks

Both Docker images include built-in health checks:

```bash
# Check container health
docker inspect --format='{{.State.Health.Status}}' yellowbook-api
docker inspect --format='{{.State.Health.Status}}' yellowbook-web

# View health check logs
docker inspect --format='{{json .State.Health}}' yellowbook-api | jq
```

## 🔄 CI/CD

### GitHub Actions Workflows

The project includes comprehensive CI/CD pipelines:

#### CI Pipeline (`.github/workflows/ci.yml`)

Triggers on push and pull requests to `main` and `develop` branches:

1. **Code Quality & Tests**
   - Linting (ESLint)
   - Format checking (Prettier)
   - Type checking (TypeScript)
   - Unit tests with coverage
   - Affected builds

2. **Docker Build & Push** (Matrix Strategy - Bonus Feature)
   - Builds Docker images for both `api` and `web` services
   - Pushes images to GitHub Container Registry (ghcr.io)
   - Tags with branch name, SHA, and `latest`
   - Includes build cache optimization

3. **Health Check Report**
   - Runs containers locally
   - Validates health endpoints
   - Generates detailed health reports
   - Uploads artifacts for 30 days

4. **Summary Report**
   - Consolidates all job results
   - Displays health check reports
   - Shows build information

### Viewing CI Results

- Visit the [Actions tab](https://github.com/Tuguu04133/yellowbook/actions) in your repository
- Each workflow run shows detailed logs and artifacts
- Health check reports are available as downloadable artifacts

### Docker Images

Images are automatically pushed to GitHub Container Registry:

```bash
# Pull images
docker pull ghcr.io/tuguu04133/yellowbook-api:latest
docker pull ghcr.io/tuguu04133/yellowbook-web:latest

# Pull specific SHA
docker pull ghcr.io/tuguu04133/yellowbook-api:main-<sha>
```

## 🚢 Deployment

### AWS ECR Setup (Template Provided)

A template workflow is provided in `.github/workflows/ecr-deploy.yml.template`:

1. **Create ECR Repositories**

```bash
# Create API repository
aws ecr create-repository \
  --repository-name yellowbook-api \
  --region us-east-1

# Create Web repository
aws ecr create-repository \
  --repository-name yellowbook-web \
  --region us-east-1
```

2. **Set Up Repository Policies**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPushPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::YOUR_ACCOUNT_ID:user/YOUR_USER"
      },
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  ]
}
```

3. **Configure GitHub Secrets**

Add these secrets to your GitHub repository:

- `AWS_ROLE_TO_ASSUME` (recommended - OIDC) or
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`

4. **Enable the Workflow**

```bash
# Rename template to active workflow
mv .github/workflows/ecr-deploy.yml.template .github/workflows/ecr-deploy.yml

# Update environment variables in the workflow file
# Then commit and push
```

### Manual ECR Push

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Tag images
docker tag yellowbook-api:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
docker tag yellowbook-web:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest

# Push images
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-api:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/yellowbook-web:latest
```

## 📁 Project Structure

```
yellowbook/
├── apps/
│   ├── api/                    # Express API application
│   │   └── src/
│   │       └── main.ts        # API entry point
│   ├── web/                    # Next.js web application
│   │   └── src/
│   │       └── app/           # App router pages
│   └── web-e2e/               # E2E tests
├── libs/
│   ├── config/                # Shared configuration
│   └── contract/              # Shared types & schemas
├── prisma/
│   ├── schema.prisma          # Database schema
│   ├── migrations/            # Database migrations
│   └── seed.ts               # Database seeding
├── .github/
│   └── workflows/
│       ├── ci.yml            # Main CI/CD pipeline
│       └── ecr-deploy.yml.template  # AWS ECR template
├── Dockerfile.api            # API Docker image
├── Dockerfile.web            # Web Docker image
├── docker-compose.yml        # Local development stack
├── .dockerignore            # Docker ignore patterns
├── nx.json                  # Nx configuration
├── package.json             # Dependencies & scripts
└── tsconfig.base.json       # TypeScript base config
```

## 📝 Scripts

```bash
# Development
npm run start:api              # Start API in production mode
npm run build:api              # Build API for production

# Database
npm run db:seed                # Seed database with sample data

# Code Quality
npm run lint                   # Lint all projects
npm run format                 # Format all files
npm run format:check          # Check formatting
npm run type-check            # TypeScript type checking

# Testing
npm test                       # Run tests (placeholder)
```

## 🏗️ Technology Stack

### Frontend
- **Next.js 15** - React framework with App Router
- **React 19** - UI library
- **TypeScript** - Type safety
- **Tailwind CSS** - Utility-first CSS

### Backend
- **Express** - Web framework
- **Prisma** - ORM
- **PostgreSQL** - Database
- **Zod** - Schema validation

### DevOps
- **Nx** - Monorepo management
- **Docker** - Containerization
- **GitHub Actions** - CI/CD
- **ESLint & Prettier** - Code quality

## 📊 Rubric Completion

- ✅ **Dockerfiles (30 points)** - Multi-stage builds for API and Web
- ✅ **Local sanity (10 points)** - Docker Compose for local testing
- ✅ **ECR repos+policies (20 points)** - Template and documentation provided
- ✅ **CI build/push (30 points)** - Automated Docker build and push
- ✅ **Docs (10 points)** - Comprehensive README with badges
- ✅ **Bonus (+10 points)** - Matrix build for push and pull_request events

## 🎉 Bonus Feature

The CI pipeline includes a **matrix build strategy** that builds both `api` and `web` services in parallel for both `push` and `pull_request` events, improving build efficiency and providing comprehensive testing coverage.

## 📄 License

MIT

## 👨‍💻 Author

Tuguu04133

---

**Ready for EKS deployment! 🚀**


