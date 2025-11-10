# Local Testing Guide

This guide explains how to test your Docker setup locally before pushing to GitHub.

## Prerequisites

- Docker Desktop installed and running
- Docker Compose installed (included with Docker Desktop)
- At least 4GB of free disk space
- PowerShell (Windows) or Bash (Linux/Mac)

## Quick Start

### Using Docker Compose (Recommended)

This is the easiest way to test everything together:

```bash
# Start all services
docker-compose up --build

# Or in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

Visit:
- Web App: http://localhost:3000
- API: http://localhost:3333

## Testing Individual Services

### Option 1: Using Test Scripts

#### On Windows (PowerShell)

```powershell
# Test all services
.\scripts\docker-test.ps1 all

# Test API only
.\scripts\docker-test.ps1 api

# Test Web only
.\scripts\docker-test.ps1 web
```

#### On Linux/Mac (Bash)

```bash
# Make script executable
chmod +x scripts/docker-test.sh

# Test all services
./scripts/docker-test.sh all

# Test API only
./scripts/docker-test.sh api

# Test Web only
./scripts/docker-test.sh web
```

### Option 2: Manual Testing

#### Build Images

```bash
# Build API image
docker build -f Dockerfile.api -t yellowbook-api:test .

# Build Web image
docker build -f Dockerfile.web -t yellowbook-web:test .
```

#### Run API Container

```bash
# Run API with PostgreSQL (recommended)
docker network create yellowbook-net

# Start PostgreSQL
docker run -d --name postgres-test \
  --network yellowbook-net \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=yellowbook \
  -p 5432:5432 \
  postgres:16-alpine

# Wait a few seconds for PostgreSQL to start
sleep 5

# Run API
docker run -d --name api-test \
  --network yellowbook-net \
  -e DATABASE_URL="postgresql://postgres:postgres@postgres-test:5432/yellowbook" \
  -e PORT=3333 \
  -p 3333:3333 \
  yellowbook-api:test

# Check logs
docker logs -f api-test

# Test endpoint
curl http://localhost:3333/
```

#### Run Web Container

```bash
# Run Web
docker run -d --name web-test \
  --network yellowbook-net \
  -e NEXT_PUBLIC_API_URL="http://localhost:3333" \
  -e PORT=3000 \
  -p 3000:3000 \
  yellowbook-web:test

# Check logs
docker logs -f web-test

# Test endpoint
curl http://localhost:3000/
```

## Health Checks

### Check Container Health Status

```bash
# API health
docker inspect --format='{{.State.Health.Status}}' api-test

# Web health
docker inspect --format='{{.State.Health.Status}}' web-test

# Detailed health info
docker inspect --format='{{json .State.Health}}' api-test | jq
```

### Manual Health Check Tests

```bash
# API health endpoint
curl http://localhost:3333/

# Expected response:
# {"message":"Yellow Book API","version":"1.0.0"}

# Web health endpoint
curl http://localhost:3000/

# Should return HTML page
```

## Testing API Endpoints

### Get All Yellow Books

```bash
curl http://localhost:3333/yellow-books
```

### Get Specific Yellow Book

```bash
curl http://localhost:3333/yellow-books/1
```

### Create Yellow Book Entry

```bash
curl -X POST http://localhost:3333/yellow-books \
  -H "Content-Type: application/json" \
  -d '{
    "businessName": "Test Business",
    "category": "Technology",
    "phoneNumber": "99119911",
    "address": "Ulaanbaatar, Mongolia",
    "description": "Test description",
    "website": "https://example.com"
  }'
```

## Debugging

### View Container Logs

```bash
# API logs
docker logs api-test

# Follow logs in real-time
docker logs -f api-test

# Last 50 lines
docker logs --tail 50 api-test

# Web logs
docker logs web-test
```

### Execute Commands in Container

```bash
# API container bash
docker exec -it api-test sh

# Inside container, check Node.js version
node --version

# Check environment variables
env | grep DATABASE

# Web container bash
docker exec -it web-test sh
```

### Check Container Resource Usage

```bash
# Real-time stats
docker stats

# Specific container
docker stats api-test web-test
```

### Inspect Container Configuration

```bash
# Full container info
docker inspect api-test

# Network settings
docker inspect --format='{{json .NetworkSettings}}' api-test | jq

# Environment variables
docker inspect --format='{{json .Config.Env}}' api-test | jq
```

## Performance Testing

### Using Apache Bench

```bash
# Install Apache Bench (if not installed)
# Ubuntu/Debian: sudo apt-get install apache2-utils
# Mac: brew install apache2

# Test API endpoint (100 requests, 10 concurrent)
ab -n 100 -c 10 http://localhost:3333/

# Test Web endpoint
ab -n 100 -c 10 http://localhost:3000/
```

### Using cURL for Load Testing

```bash
# Simple load test (10 sequential requests)
for i in {1..10}; do
  curl -w "\n%{time_total}s\n" http://localhost:3333/yellow-books
done
```

## Database Testing

### Access PostgreSQL Database

```bash
# Connect to database
docker exec -it postgres-test psql -U postgres -d yellowbook

# Inside PostgreSQL:
# List tables
\dt

# View yellow_books
SELECT * FROM yellow_books;

# Exit
\q
```

### Reset Database

```bash
# Stop API container
docker stop api-test

# Drop and recreate database
docker exec postgres-test psql -U postgres -c "DROP DATABASE IF EXISTS yellowbook;"
docker exec postgres-test psql -U postgres -c "CREATE DATABASE yellowbook;"

# Restart API (migrations run automatically)
docker start api-test
```

## Cleanup

### Remove Test Containers

```bash
# Stop all test containers
docker stop api-test web-test postgres-test

# Remove containers
docker rm api-test web-test postgres-test

# Remove network
docker network rm yellowbook-net
```

### Remove Images

```bash
# Remove test images
docker rmi yellowbook-api:test yellowbook-web:test

# Remove dangling images
docker image prune -f
```

### Full Cleanup

```bash
# Stop and remove everything from docker-compose
docker-compose down -v

# Remove all unused containers, networks, images
docker system prune -a --volumes -f
```

## Troubleshooting

### Port Already in Use

```bash
# Find process using port
# Windows PowerShell:
netstat -ano | findstr :3333

# Linux/Mac:
lsof -i :3333

# Kill the process or use different port
docker run -p 3334:3333 ...
```

### Container Crashes Immediately

```bash
# Check logs
docker logs api-test

# Common issues:
# - DATABASE_URL not set or incorrect
# - Port already in use
# - Missing dependencies in build
```

### Health Check Never Passes

```bash
# Check if app is listening on correct port
docker exec api-test netstat -tulpn

# Check if health endpoint works inside container
docker exec api-test wget -O- http://localhost:3333/

# Increase health check timeout in Dockerfile
```

### Build Fails

```bash
# Clear build cache
docker builder prune -af

# Rebuild without cache
docker build --no-cache -f Dockerfile.api -t yellowbook-api:test .

# Check .dockerignore
cat .dockerignore
```

### Network Issues

```bash
# Test network connectivity
docker network inspect yellowbook-net

# Ping between containers
docker exec api-test ping postgres-test

# Check DNS resolution
docker exec api-test nslookup postgres-test
```

## CI/CD Simulation

Simulate the GitHub Actions workflow locally:

```bash
# 1. Lint
npm run lint

# 2. Format check
npm run format:check

# 3. Type check
npm run type-check

# 4. Tests
npx nx affected -t test --parallel=3

# 5. Build
npx nx affected -t build --parallel=3

# 6. Docker build
docker build -f Dockerfile.api -t yellowbook-api:test .
docker build -f Dockerfile.web -t yellowbook-web:test .

# 7. Health checks (use test scripts)
.\scripts\docker-test.ps1 all  # Windows
./scripts/docker-test.sh all    # Linux/Mac
```

## Next Steps

Once local testing passes:

1. Commit and push to GitHub
2. Check GitHub Actions for green builds
3. Verify Docker images in GitHub Container Registry
4. Proceed with AWS ECR setup (see docs/AWS-ECR-SETUP.md)

## Useful Commands Reference

```bash
# List all running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List all images
docker images

# View disk usage
docker system df

# Real-time events
docker events

# Container top processes
docker top api-test

# Copy files from container
docker cp api-test:/app/dist ./dist-backup
```

## Performance Benchmarks

Expected response times on a typical development machine:

- API health endpoint: < 50ms
- API GET /yellow-books: < 200ms
- Web page load: < 1000ms

If you see significantly slower times:
- Check system resources (CPU, Memory, Disk)
- Ensure Docker has enough allocated resources
- Verify database connection is not slow
- Check for build optimization issues
